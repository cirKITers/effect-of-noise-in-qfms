from qml_essentials.model import Model
from qml_essentials.coefficients import Coefficients
import pennylane.numpy as np
import plotly.graph_objects as go
import plotly.express as px
from rich.progress import Progress, Task
from typing import Dict, Tuple, Optional
import mlflow
import pandas as pd

import logging

from effects_of_noise_in_qfm.helpers.utils import NoiseDict


log = logging.getLogger(__name__)


def iterate_layers(
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
    model_degrees = np.ndarray(
        (n_layers),
        dtype=int,
    )

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

            coeffs = Coefficients.sample_coefficients(model=model)

            coeff_z = coeffs[0]
            coeffs_nz = coeffs[1:]
            coeffs_p = coeffs_nz[len(coeffs_nz) // 2 :]
            coeffs_pl[n][s] = coeffs_p[-1]

            model_degrees[n] = model.degree

            if progress is not None:
                progress.update(sample_coeff_task, advance=1)
        if progress is not None:
            progress.update(layer_it_task, advance=1)

    coeffs_plr = coeffs_pl.real
    coeffs_pli = coeffs_pl.imag

    return coeffs_plr, coeffs_pli, model_degrees


def iterate_noise_and_layers(
    model: Model, noise_params: Dict[str, float], noise_steps: int, n_samples: int
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

    noise_params = NoiseDict(noise_params)

    df = pd.DataFrame(
        columns=[
            *[n for n in noise_params.keys()],
            "noise_level",
            "layers",
            "coeffs_abs_var",
            "coeffs_abs_mean",
        ]
    )

    with Progress() as progress:
        noise_it_task = progress.add_task(
            "Iterating noise levels...", total=noise_steps
        )
        layer_it_task = progress.add_task("Iterating layers...", total=model.n_layers)
        sample_coeff_task = progress.add_task("Sampling...", total=n_samples)

        colors = px.colors.qualitative.Dark2
        for step in range(noise_steps + 1):  # +1 to go for 100%
            part_noise_params = noise_params * (step / noise_steps)

            coeffs_plr, coeffs_pli, model_degrees = iterate_layers(
                n_qubits=model.n_qubits,
                n_layers=model.n_layers,
                ansatz=model.pqc.__class__.__name__,
                samples=n_samples,
                noise_params=part_noise_params,
                progress=progress,
                layer_it_task=layer_it_task,
                sample_coeff_task=sample_coeff_task,
            )
            coeffs_abs = np.sqrt(coeffs_plr**2 + coeffs_pli**2)

            for n, v in part_noise_params.items():
                df.loc[step, n] = v
            df.loc[step, "noise_level"] = step / noise_steps
            df.loc[step, "layers"] = model_degrees
            df.loc[step, "coeffs_abs_var"] = coeffs_abs.var(axis=1)
            df.loc[step, "coeffs_abs_mean"] = coeffs_abs.mean(axis=1)

            fig.add_trace(
                go.Scatter(
                    x=model_degrees,
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

    return {"coefficients_noise_layers": df}


def iterate_noise(
    model: Model,
    noise_params: Dict[str, float],
    noise_steps: int,
    n_samples: int,
    seed: int,
    zero_coefficient: bool,
    oversampling: int = 1,
    selective_noise: str = "both",
    scale=False,
) -> None:
    noise_params = NoiseDict(noise_params)

    df = pd.DataFrame(
        columns=[
            *[n for n in noise_params.keys()],
            "noise_level",
            "coeffs_abs_var",  # Variance of the absolute coefficients
            "coeffs_var",  # Variance of complex coefficients
            "coeffs_co_var_real_imag",  # Covariance of real and imaginary part
            "coeffs_real_var",  # Variance of real parts only
            "coeffs_imag_var",  # Variance of imaginary parts only
            "coeffs_abs_mean",  # Mean absolute coefficient
            "coeffs_real_mean",  # Mean of real part only
            "coeffs_imag_mean",  # Mean of imaginary part only
            "coeffs_full_real",  # All coefficients real part
            "coeffs_full_imag",  # All coefficients imaginary part
            "frequencies",
        ]
    )
    rng = np.random.default_rng(seed)

    enc = model._enc

    def enc_noise_free(*args, **kwargs):
        kwargs["noise_params"] = None
        return enc(*args, **kwargs)

    pqc = model.pqc

    def pqc_noise_free(*args, **kwargs):
        kwargs["noise_params"] = None
        return pqc(*args, **kwargs)

    if selective_noise == "iec":
        model.pqc = pqc_noise_free
    elif selective_noise == "pqc":
        model._enc = enc_noise_free
    elif selective_noise != "both":
        raise ValueError(
            f"selective_noise must be 'both', 'iec' or 'pqc', got {selective_noise}"
        )

    if scale:
        n_samples = int(np.power(2, model.n_qubits) * n_samples)

    with Progress() as progress:
        noise_it_task = progress.add_task(
            "Iterating noise levels...", total=noise_steps + 1
        )
        sample_coeff_task = progress.add_task("Sampling...", total=n_samples)

        for step in range(0, noise_steps + 1):  # +1 to go for 100%
            progress.reset(sample_coeff_task)
            part_noise_params = noise_params * (step / noise_steps)

            coeffs = []
            freqs = []
            # Re-initialize model, because it triggers new sampling
            model.initialize_params(rng=rng, repeat=n_samples)

            cs, f = Coefficients.get_spectrum(
                model=model,
                mts=oversampling,
                shift=True,
                trim=True,
                noise_params=part_noise_params,
            )

            for it in range(n_samples):
                c = cs[..., it]
                if model.n_input_feat == 1:
                    if zero_coefficient:
                        coeffs.append(c[len(c) // 2 :])
                        freqs.append(f[len(f) // 2 :])
                    else:
                        coeffs.append(c[len(c) // 2 + 1 :])
                        freqs.append(f[len(f) // 2 + 1 :])
                else:
                    coeffs.append(c)
                    _f = np.stack(np.meshgrid(*[f] * model.n_input_feat)).T.reshape(
                        *c.shape, model.n_input_feat
                    )
                    freqs.append(_f)

                progress.update(sample_coeff_task, advance=1)

            for n, v in part_noise_params.items():
                if n == "ThermalRelaxation":
                    if isinstance(v, dict):
                        df.loc[step, "ThermalRelaxation"] = v["t_factor"]
                    else:
                        df.loc[step, "ThermalRelaxation"] = 0.0
                else:
                    df.loc[step, n] = v
            df.loc[step, "noise_level"] = step / noise_steps

            mean_real = np.real(coeffs).mean(axis=0)
            mean_imag = np.imag(coeffs).mean(axis=0)
            co_variance_real_imag = np.mean(
                (np.real(coeffs) - mean_real) * (np.imag(coeffs) - mean_imag),
                axis=0,
            )

            df.loc[step, "coeffs_abs_var"] = np.abs(coeffs).var(axis=0).tolist()
            df.loc[step, "coeffs_var"] = np.array(coeffs).var(axis=0).tolist()
            df.loc[step, "coeffs_co_var_real_imag"] = co_variance_real_imag.tolist()
            df.loc[step, "coeffs_real_var"] = np.real(coeffs).var(axis=0).tolist()
            df.loc[step, "coeffs_imag_var"] = np.imag(coeffs).var(axis=0).tolist()
            df.loc[step, "coeffs_abs_mean"] = np.abs(coeffs).mean(axis=0).tolist()
            df.loc[step, "coeffs_real_mean"] = mean_real.tolist()
            df.loc[step, "coeffs_imag_mean"] = mean_imag.tolist()
            df.loc[step, "coeffs_full_real"] = np.array(coeffs).T.real.tolist()
            df.loc[step, "coeffs_full_imag"] = np.array(coeffs).T.imag.tolist()
            df.loc[step, "frequencies"] = freqs[0].tolist()

            progress.advance(noise_it_task)

    return {"coefficients_noise": df}
