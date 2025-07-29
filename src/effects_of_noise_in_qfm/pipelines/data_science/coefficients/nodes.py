from qml_essentials.model import Model
from qml_essentials.coefficients import Coefficients
from qml_essentials.ansaetze import Gates
import pennylane.numpy as np
from rich.progress import Progress
from typing import Dict
import pandas as pd
from functools import partial
import logging

from effects_of_noise_in_qfm.helpers.utils import NoiseDict


log = logging.getLogger(__name__)


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

    def enc_noise_free(i, *args, **kwargs):
        kwargs["noise_params"] = None
        ret = enc[i](*args, **kwargs)
        return ret

    pqc = model.pqc

    def pqc_noise_free(*args, **kwargs):
        kwargs["noise_params"] = None
        return pqc(*args, **kwargs)

    def pqc_no_batch_gate_error(*args, **kwargs):
        Gates.batch_gate_error = False
        ret = pqc(*args, **kwargs)
        Gates.batch_gate_error = True
        return ret

    if selective_noise == "iec":
        model.pqc = pqc_noise_free
    elif selective_noise == "pqc":
        model._enc = [partial(enc_noise_free, i) for i in range(len(model._enc))]
        model.pqc = pqc_no_batch_gate_error
    elif selective_noise != "both":
        raise ValueError(
            f"selective_noise must be 'both', 'iec' or 'pqc', got {selective_noise}"
        )
    else:
        model.pqc = pqc_no_batch_gate_error

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

    import plotly.graph_objects as go
    import plotly.colors as pc

    colors = pc.sequential.Plasma
    fig = go.Figure(
        data=[
            go.Scatter(
                x=df.frequencies[i],
                y=df.coeffs_abs_mean.iloc[i],
                mode="markers",
                name=f"Noise level {df.noise_level[i]:.2f}",
                marker=dict(color=colors[i]),
            )
            for i in range(noise_steps + 1)
        ]
    )
    fig.update_layout(
        title="Absolute value of the coefficients",
        xaxis_title="Frequency",
        yaxis_title="Absolute value of the coefficient",
        template="plotly_white",
    )
    fig.show()
    return {"coefficients_noise": df}
