from qml_essentials.model import Model
from functools import partial
from pennylane.fourier import coefficients
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from rich.progress import Progress, Task
from typing import Dict, Tuple, Optional
import mlflow

import logging

log = logging.getLogger(__name__)


def sample_coefficients(model: Model) -> np.ndarray:
    """
    Sample the Fourier coefficients of a given model.

    Args:
        model (Model): The model to sample.

    Returns:
        np.ndarray: The sampled Fourier coefficients.
    """
    partial_circuit = partial(model, model.params)
    return coefficients(partial_circuit, 1, model.degree)


def iterate_layers_and_sample(
    n_qubits: int,
    n_layers: int,
    ansatz: str,
    samples: int,
    noise_params: Dict[str, float],
    progress: Optional[Progress] = None,
    layer_it_task: Optional[Task] = None,
    sample_coeff_task: Optional[Task] = None,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Iterate over layers and sample coefficients.

    Args:
        n_qubits (int): Number of qubits.
        n_layers (int): Number of layers.
        ansatz (str): Ansatz type.
        samples (int): Number of samples.
        noise_params (Dict[str, float]): Noise parameters.
        progress (Optional[rich.progress.Progress]): Progress bar.
        layer_it_task (Optional[rich.progress.Task]): Task for layer iteration.
        sample_coeff_task (Optional[rich.progress.Task]): Task for coefficient sampling.

    Returns:
        Tuple[np.ndarray, np.ndarray]: Real and imaginary parts of the sampled coefficients.
    """
    coeffs_pl = np.ndarray((n_layers, samples), dtype=complex)

    if progress is not None:
        progress.reset(layer_it_task)
    for n in range(n_layers):
        if progress is not None:
            progress.reset(sample_coeff_task)
        for s in range(samples):
            # Re-initialize model, because it triggers new sampling
            model = Model(
                n_qubits=n_qubits,
                n_layers=n + 1,  # starting at 0 is silly
                circuit_type=ansatz,
            )
            model.noise_params = noise_params

            coeffs = sample_coefficients(model=model)

            coeff_z = coeffs[0]
            coeffs_nz = coeffs[1:]
            coeffs_p = coeffs_nz[len(coeffs_nz) // 2 :]
            coeffs_pl[n][s] = coeffs_p[-1]

            if progress is not None:
                progress.update(sample_coeff_task, advance=1)
        if progress is not None:
            progress.update(layer_it_task, advance=1)

    coeffs_plr = coeffs_pl.real
    coeffs_pli = coeffs_pl.imag

    return coeffs_plr, coeffs_pli


def iterate_layers_and_noise(
    model: Model, noise_params: Dict[str, float], noise_steps: int, samples: int
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

    with Progress() as progress:
        noise_it_task = progress.add_task(
            "Iterating noise levels...", total=noise_steps + 1
        )
        layer_it_task = progress.add_task("Iterating layers...", total=model.n_layers)
        sample_coeff_task = progress.add_task("Sampling...", total=samples)

        colors = px.colors.qualitative.Dark2
        for step in range(noise_steps + 1):  # +1 to go for 100%
            part_noise_params = noise_params * (step / noise_steps)

            coeffs_plr, coeffs_pli = iterate_layers_and_sample(
                n_qubits=model.n_qubits,
                n_layers=model.n_layers,
                ansatz=model.pqc.__class__.__name__,
                samples=samples,
                noise_params=part_noise_params,
                progress=progress,
                layer_it_task=layer_it_task,
                sample_coeff_task=sample_coeff_task,
            )
            coeffs_abs = np.sqrt(coeffs_plr**2 + coeffs_pli**2)

            fig.add_trace(
                go.Scatter(
                    x=np.arange(1, model.n_layers + 1),
                    y=coeffs_abs.var(axis=1),
                    mode="lines+markers",
                    name=f"Rel. Noise Level: {(step/noise_steps)*100:.0f}%",
                    marker=dict(
                        size=10,
                        color=colors[step],
                    ),
                )
            )

            progress.advance(noise_it_task)

    fig.update_layout(
        xaxis_title="# of Unique Frequencies",
        yaxis_title="Variance of HF Coefficient (abs)",
        title=f"Variance of Coefficients for {model.pqc.__class__.__name__} Ansatz",
        template="simple_white",
        legend=dict(yanchor="top", y=1.0, xanchor="left", x=0.71),
    )

    fig.update_yaxes(type="log")

    mlflow.log_figure(fig, "coefficients.html")
