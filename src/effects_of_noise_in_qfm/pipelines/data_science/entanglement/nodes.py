from qml_essentials.model import Model
from qml_essentials.entanglement import Entanglement
from rich.progress import Progress
import pandas as pd
from typing import Dict, List, Optional
import jax
import numpy as np
import mlflow
import logging

from effects_of_noise_in_qfm.helpers.utils import NoiseDict, input_grid

log = logging.getLogger(__name__)


def calculate_entanglement(
    model: Model,
    samples: int,
    sigmas: int,
    scale: bool,
    seed: int,
    noise_params: Dict,
    measure: str,
    n_inputs: int = 0,
    domain: Optional[List[float]] = None,
    iterator=None,
    return_per_input: bool = False,
):
    """
    Calculate the entangling capability.

    With ``n_inputs == 0`` the states are evaluated at x = 0 (zero-input
    protocol). With ``n_inputs > 0`` the measure is evaluated with the same
    parameter samples at each of ``n_inputs`` evenly spaced inputs over
    ``domain`` and reported per input (``return_per_input``) or as the mean
    over the inputs.
    """
    kwargs = dict()
    if measure == "RE":
        ent_measure = Entanglement.relative_entropy
        kwargs["n_sigmas"] = sigmas
    elif measure == "EF":
        ent_measure = Entanglement.entanglement_of_formation
    elif measure == "MW":
        ent_measure = Entanglement.meyer_wallach
    elif measure == "MN":
        ent_measure = Entanglement.mean_negativity
    else:
        exit(f"Unknown Entanglement Measure: {measure}")

    if n_inputs > 0:
        xs, grid = input_grid(model, n_inputs, domain)
        entangling_capability = np.zeros(n_inputs)
        for i, x in enumerate(grid):
            # the same random key yields the same parameter samples for every input
            entangling_capability[i] = ent_measure(
                model=model,
                n_samples=samples,
                random_key=jax.random.key(seed),
                scale=scale,
                inputs=x,
                noise_params=noise_params,
                **kwargs,
            )
            log.info(
                f"Calculated entangling capability at input {xs[i]}: "
                f"{entangling_capability[i]}"
            )
            if iterator is not None:
                mlflow.log_metric(
                    f"entangling_capability_input{i}",
                    entangling_capability[i],
                    step=iterator,
                )
        if iterator is not None:
            mlflow.log_metric(
                "entangling_capability", float(entangling_capability.mean()), step=iterator
            )
        if return_per_input:
            return xs, entangling_capability
        return float(entangling_capability.mean())

    entangling_capability = ent_measure(
        model=model,
        n_samples=samples,
        random_key=jax.random.key(seed),
        scale=scale,
        inputs=None,
        noise_params=noise_params,
        **kwargs,
    )

    log.info(f"Calculated entangling capability: {entangling_capability}")
    if iterator is not None:
        mlflow.log_metric("entangling_capability", entangling_capability, step=iterator)

    return entangling_capability


def iterate_noise(
    model: Model,
    noise_params: Dict[str, float],
    noise_steps: int,
    n_samples: int,
    n_sigmas: int,
    scale: bool,
    seed: int,
    measure: str,
    n_inputs: int = 0,
    domain: Optional[List[float]] = None,
) -> None:
    """
    Iterates over different noise levels and calculates the entangling capability
    for each level using the given model and noise parameters.

    Args:
        model: The quantum model to evaluate.
        noise_params: A dictionary of noise parameters with their initial values.
        noise_steps: The number of steps to incrementally apply noise.
        n_samples: The number of samples to use in the entangling capability calculation.
        seed: The random seed for reproducibility.
        n_inputs: 0 for the zero-input protocol, otherwise the number of fixed
            inputs (evenly spaced over ``domain``) at which the measure is
            evaluated; one row per noise level and input is recorded with the
            additional columns ``input_idx`` and ``input_value``.
        domain: Input domain used for the input grid.

    Returns:
        A dictionary containing a DataFrame with the calculated entangling capability
        and noise levels for each step.
    """

    noise_params = NoiseDict(noise_params)

    columns = [*[n for n in noise_params.keys()], "noise_level"]
    if n_inputs > 0:
        columns += ["input_idx", "input_value"]
    df = pd.DataFrame(columns=columns + ["entangling_capability"])

    with Progress() as progress:
        noise_it_task = progress.add_task(
            "Iterating noise levels...", total=noise_steps + 1
        )

        for step in range(noise_steps + 1):  # +1 to go for 100%
            part_noise_params = noise_params * (step / noise_steps)

            if n_inputs > 0:
                xs, entangling_capability = calculate_entanglement(
                    model=model,
                    samples=n_samples,
                    sigmas=n_sigmas,
                    scale=scale,
                    seed=seed,
                    noise_params=part_noise_params,
                    iterator=step,
                    measure=measure,
                    n_inputs=n_inputs,
                    domain=domain,
                    return_per_input=True,
                )
                for i, (x, e) in enumerate(zip(xs, entangling_capability)):
                    row = step * n_inputs + i
                    for n, v in part_noise_params.items():
                        df.loc[row, n] = v
                    df.loc[row, "noise_level"] = step / noise_steps
                    df.loc[row, "input_idx"] = i
                    df.loc[row, "input_value"] = float(x)
                    df.loc[row, "entangling_capability"] = float(e)
            else:
                entangling_capability = calculate_entanglement(
                    model=model,
                    samples=n_samples,
                    sigmas=n_sigmas,
                    scale=scale,
                    seed=seed,
                    noise_params=part_noise_params,
                    iterator=step,
                    measure=measure,
                )

                for n, v in part_noise_params.items():
                    df.loc[step, n] = v
                df.loc[step, "noise_level"] = step / noise_steps
                df.loc[step, "entangling_capability"] = entangling_capability

            progress.advance(noise_it_task)

    return {"entangling_capability_noise": df}
