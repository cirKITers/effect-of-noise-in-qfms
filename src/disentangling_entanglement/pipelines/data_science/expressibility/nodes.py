from typing import Dict, List
import logging
import mlflow
import plotly.graph_objects as go
import plotly.express as px
from rich.progress import Progress, Task
import pandas as pd

from qml_essentials.model import Model
from qml_essentials.expressibility import Expressibility

log = logging.getLogger(__name__)


def calculate_expressibility(
    model: Model,
    n_samples: int,
    n_input_samples: int,
    n_bins: int,
    seed: int,
    input_domain: List[float],
    noise_params: Dict,
):
    x, _, z = Expressibility.state_fidelities(
        n_bins=n_bins,
        n_samples=n_samples,
        input_domain=input_domain,
        n_input_samples=n_input_samples,
        seed=seed,
        model=model,
        noise_params=noise_params,
        cache=True,
    )

    _, y_haar = Expressibility.haar_integral(
        n_qubits=model.n_qubits, n_bins=n_bins, cache=True
    )

    kl_divergence = Expressibility.kullback_leibler_divergence(
        vqc_prob_dist=z, haar_dist=y_haar
    )

    log.debug(f"KL Divergence {kl_divergence}")

    for i, prob in enumerate(y_haar):
        mlflow.log_metric("haar_probability", prob, i)

    for i, (x_sample, kl) in enumerate(zip(x, kl_divergence)):
        mlflow.log_metric("kl_divergence", kl, i)
        mlflow.log_metric("x", x_sample, i)

        for j, fidelity in enumerate(z[i]):
            mlflow.log_metric(f"x_{x_sample:.2f}_fidelity", fidelity, j)

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
    Iterate over noise params and plot the variance of coefficients for each layer.

    Args:
        model: The model to sample coefficients from.
        noise_params: The noise parameters to iterate over.
        noise_steps: The number of noise steps to iterate over.
        samples: The number of samples to take for each step.

    Returns:
        None
    """
    fig = go.Figure()

    class NoiseDict(Dict[str, float]):
        """
        A dictionary subclass for noise params.
        """

        def __truediv__(self, other: float) -> "NoiseDict":
            """
            Divide all values by a scalar.
            """
            return NoiseDict({k: v / other for k, v in self.items()})

        def __mul__(self, other: float) -> "NoiseDict":
            """
            Multiply all values by a scalar.
            """
            return NoiseDict({k: v * other for k, v in self.items()})

    noise_params = NoiseDict(noise_params)

    df = pd.DataFrame(columns=["noise", "expressibility"])

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
            )
            mlflow.log_metric("expressibility", expressibility, step)

            progress.advance(noise_it_task)
