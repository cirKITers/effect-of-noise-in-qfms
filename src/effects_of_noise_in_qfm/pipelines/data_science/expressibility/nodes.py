from typing import Dict, List
import logging
import mlflow
import plotly.graph_objects as go
import plotly.express as px
from rich.progress import Progress, Task
import pandas as pd

from qml_essentials.model import Model
from qml_essentials.expressibility import Expressibility

from effects_of_noise_in_qfm.helpers.utils import NoiseDict

log = logging.getLogger(__name__)


def calculate_expressibility(
    model: Model,
    n_samples: int,
    n_bins: int,
    seed: int,
    noise_params: Dict,
    n_input_samples: int = None,
    input_domain: List[float] = None,
    iterator=None,
):
    x, _, z = Expressibility.state_fidelities(
        n_bins=n_bins,
        n_samples=n_samples,
        input_domain=input_domain,
        n_input_samples=n_input_samples,
        seed=seed,
        model=model,
        noise_params=noise_params,
        scale=True,
        cache=False,
    )

    _, y_haar = Expressibility.haar_integral(
        n_qubits=model.n_qubits, n_bins=n_bins, scale=True, cache=True
    )

    kl_divergence = Expressibility.kullback_leibler_divergence(
        vqc_prob_dist=z, haar_dist=y_haar
    )

    log.debug(f"KL Divergence {kl_divergence}")

    for i, prob in enumerate(y_haar):
        mlflow.log_metric("haar_probability", prob, i)

    # TODO: I feel like the following part should rather go into a dataframe
    if n_input_samples is not None and n_input_samples > 0 and input_domain is not None:
        for i, (x_sample, kl) in enumerate(zip(x, kl_divergence)):
            mlflow.log_metric("kl_divergence", kl, i)
            mlflow.log_metric("x", x_sample, i)

            for j, fidelity in enumerate(z[i]):
                mlflow.log_metric(f"x_{x_sample:.2f}_fidelity", fidelity, j)
    elif iterator is not None:
        mlflow.log_metric("kl_divergence", kl_divergence, step=iterator)

    return kl_divergence


def iterate_noise(
    model: Model,
    noise_params: Dict[str, float],
    noise_steps: int,
    n_samples: int,
    n_bins: int,
    seed: int,
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

    Returns:
        A dictionary containing a DataFrame with the calculated expressibility
        and noise levels for each step.
    """

    noise_params = NoiseDict(noise_params)

    df = pd.DataFrame(
        columns=[*[n for n in noise_params.keys()], "noise_level", "expressibility"]
    )

    with Progress() as progress:
        noise_it_task = progress.add_task(
            "Iterating noise levels...", total=noise_steps + 1
        )

        for step in range(noise_steps + 1):  # +1 to go for 100%
            part_noise_params = noise_params * (step / noise_steps)

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
