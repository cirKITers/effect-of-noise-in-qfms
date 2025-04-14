from qml_essentials.model import Model
from qml_essentials.entanglement import Entanglement
from rich.progress import Progress
import pandas as pd
from typing import Dict
import mlflow
import logging

from effects_of_noise_in_qfm.helpers.utils import NoiseDict

log = logging.getLogger(__name__)


def calculate_entanglement(
    model: Model,
    samples: int,
    sigmas: int,
    scale: bool,
    seed: int,
    noise_params: Dict,
    measure: str,
    iterator=None,
):
    kwargs = dict()
    if measure == "RE":
        ent_measure = Entanglement.relative_entropy
        kwargs["n_sigmas"] = sigmas
    elif measure == "EF":
        ent_measure = Entanglement.entanglement_of_formation
        kwargs["always_decompose"] = True
    elif measure == "MW":
        ent_measure = Entanglement.meyer_wallach
    else:
        exit(f"Unknown Entanglement Measure: {measure}")

    entangling_capability = ent_measure(
        model=model,
        n_samples=samples,
        seed=seed,
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

    Returns:
        A dictionary containing a DataFrame with the calculated entangling capability
        and noise levels for each step.
    """

    noise_params = NoiseDict(noise_params)

    df = pd.DataFrame(
        columns=[
            *[n for n in noise_params.keys()],
            "noise_level",
            "entangling_capability",
        ]
    )

    with Progress() as progress:
        noise_it_task = progress.add_task(
            "Iterating noise levels...", total=noise_steps + 1
        )

        for step in range(noise_steps + 1):  # +1 to go for 100%
            part_noise_params = noise_params * (step / noise_steps)

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
