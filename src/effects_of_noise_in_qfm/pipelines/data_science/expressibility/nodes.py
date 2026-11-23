from typing import Dict, List, Optional, Tuple
import logging
import jax
import jax.numpy as jnp
import numpy as np
import mlflow
from rich.progress import Progress, Task
import pandas as pd
from scipy.linalg import sqrtm

from qml_essentials.model import Model
from qml_essentials.expressibility import Expressibility

from effects_of_noise_in_qfm.helpers.utils import NoiseDict, input_grid

log = logging.getLogger(__name__)


def _state_fidelities_fixed_input(
    model: Model,
    n_samples: int,
    n_bins: int,
    random_key: jax.Array,
    inputs: np.ndarray,
    noise_params: Dict,
) -> jnp.ndarray:
    """
    Sample the fidelity histogram of the model states at one fixed input.

    Mirrors ``Expressibility.state_fidelities`` (scale=True), but evaluates
    all parameter samples at the given input instead of at x = 0. The same
    random key yields the same parameter samples for every input.

    Args:
        model (Model): The quantum model.
        n_samples (int): Number of state pairs per qubit-dimension (scaled by
            2**n_qubits as in the library).
        n_bins (int): Number of bins per qubit (scaled by n_qubits).
        random_key (jax.Array): Key for the parameter samples.
        inputs (np.ndarray): One input of shape (1, n_input_feat).
        noise_params (Dict): Noise parameters.

    Returns:
        jnp.ndarray: Normalised fidelity histogram with n_qubits * n_bins bins.
    """
    n_samples = int(2**model.n_qubits * n_samples)
    n_bins = model.n_qubits * n_bins

    model.initialize_params(random_key, repeat=n_samples * 2)
    rhos = model(
        params=model.params,
        inputs=inputs,
        execution_type="density",
        noise_params=noise_params,
    )
    dim = 2**model.n_qubits
    rhos = jnp.asarray(rhos).reshape(-1, dim, dim)

    sqrt_rho = jnp.array([sqrtm(m) for m in rhos[:n_samples]])
    inner = sqrt_rho @ rhos[n_samples:] @ sqrt_rho
    fidelities = (
        jnp.trace(jnp.array([sqrtm(m) for m in inner]), axis1=1, axis2=2) ** 2
    )
    fidelities = jnp.abs(fidelities)

    z, _ = jnp.histogram(fidelities, bins=jnp.linspace(0, 1, n_bins + 1))
    return z / n_samples


def calculate_expressibility(
    model: Model,
    n_samples: int,
    n_bins: int,
    seed: int,
    noise_params: Dict,
    n_inputs: int = 0,
    domain: Optional[List[float]] = None,
    iterator=None,
    return_per_input: bool = False,
):
    """
    Calculate the KL divergence of the sampled fidelity distribution from the
    Haar reference.

    With ``n_inputs == 0`` the states are evaluated at x = 0 (zero-input
    protocol). With ``n_inputs > 0`` the fidelity distribution is evaluated at
    ``n_inputs`` evenly spaced inputs over ``domain`` (same parameter samples
    for every input), and the KL divergence is computed per input.

    Returns:
        float: KL divergence (mean over inputs if ``n_inputs > 0``), or with
        ``return_per_input`` a tuple (input values, per-input KL divergences).
    """
    _, y_haar = Expressibility.haar_integral(
        n_qubits=model.n_qubits, n_bins=n_bins, scale=True, cache=True
    )

    if n_inputs > 0:
        xs, grid = input_grid(model, n_inputs, domain)
        kl_divergence = np.zeros(n_inputs)
        for i, x in enumerate(grid):
            z = _state_fidelities_fixed_input(
                model=model,
                n_samples=n_samples,
                n_bins=n_bins,
                random_key=jax.random.key(seed),
                inputs=x,
                noise_params=noise_params,
            )
            kl_divergence[i] = Expressibility.kullback_leibler_divergence(
                vqc_prob_dist=z, haar_dist=y_haar
            )[0]
            log.debug(f"KL Divergence at input {xs[i]}: {kl_divergence[i]}")
            if iterator is not None:
                mlflow.log_metric(f"kl_divergence_input{i}", kl_divergence[i], step=iterator)
    else:
        _, z = Expressibility.state_fidelities(
            n_bins=n_bins,
            n_samples=n_samples,
            random_key=jax.random.key(seed),
            model=model,
            noise_params=noise_params,
            scale=True,
        )
        kl_divergence = Expressibility.kullback_leibler_divergence(
            vqc_prob_dist=z, haar_dist=y_haar
        )
        xs = None

    log.debug(f"KL Divergence {kl_divergence}")

    for i, prob in enumerate(y_haar):
        mlflow.log_metric("haar_probability", prob, i)

    if iterator is not None:
        mlflow.log_metric("kl_divergence", float(np.mean(kl_divergence)), step=iterator)

    if return_per_input:
        return xs, kl_divergence
    return float(np.mean(kl_divergence))


def iterate_noise(
    model: Model,
    noise_params: Dict[str, float],
    noise_steps: int,
    n_samples: int,
    n_bins: int,
    seed: int,
    n_inputs: int = 0,
    domain: Optional[List[float]] = None,
) -> None:
    """
    Iterate over different noise levels and calculate the expressibility
    for each level using the given model and noise parameters.

    Args:
        model: The quantum model to evaluate.
        noise_params: A dictionary of noise parameters with their initial values.
        noise_steps: The number of steps to incrementally apply noise.
        n_samples: The number of samples to use in the expressibility calculation.
        n_bins: The number of bins for the expressibility calculation.
        seed: The random seed for reproducibility.
        n_inputs: 0 for the zero-input protocol, otherwise the number of fixed
            inputs (evenly spaced over ``domain``) at which the expressibility
            is evaluated; one row per noise level and input is recorded with
            the additional columns ``input_idx`` and ``input_value``.
        domain: Input domain used for the input grid.

    Returns:
        A dictionary containing a DataFrame with the calculated expressibility
        and noise levels for each step.
    """

    noise_params = NoiseDict(noise_params)

    columns = [*[n for n in noise_params.keys()], "noise_level", "expressibility"]
    if n_inputs > 0:
        columns = columns[:-1] + ["input_idx", "input_value", "expressibility"]
    df = pd.DataFrame(columns=columns)

    with Progress() as progress:
        noise_it_task = progress.add_task(
            "Iterating noise levels...", total=noise_steps + 1
        )

        for step in range(noise_steps + 1):  # +1 to go for 100%
            part_noise_params = noise_params * (step / noise_steps)

            if n_inputs > 0:
                xs, expressibility = calculate_expressibility(
                    model=model,
                    n_samples=n_samples,
                    n_bins=n_bins,
                    seed=seed,
                    noise_params=part_noise_params,
                    n_inputs=n_inputs,
                    domain=domain,
                    iterator=step,
                    return_per_input=True,
                )
                for i, (x, e) in enumerate(zip(xs, expressibility)):
                    row = step * n_inputs + i
                    for n, v in part_noise_params.items():
                        df.loc[row, n] = v
                    df.loc[row, "noise_level"] = step / noise_steps
                    df.loc[row, "input_idx"] = i
                    df.loc[row, "input_value"] = float(x)
                    df.loc[row, "expressibility"] = float(e)
            else:
                expressibility = calculate_expressibility(
                    model=model,
                    n_samples=n_samples,
                    n_bins=n_bins,
                    seed=seed,
                    noise_params=part_noise_params,
                    iterator=step,
                )

                for n, v in part_noise_params.items():
                    df.loc[step, n] = v
                df.loc[step, "noise_level"] = step / noise_steps
                df.loc[step, "expressibility"] = expressibility

            progress.advance(noise_it_task)

    return {"expressibility_noise": df}
