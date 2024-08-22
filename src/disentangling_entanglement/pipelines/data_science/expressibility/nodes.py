from typing import Dict
import logging
import mlflow

from qml_essentials.model import Model
from qml_essentials.expressibility import Expressibility

log = logging.getLogger(__name__)


def calculate_expressibility(
    model: Model,
    n_samples: int,
    n_input_samples: int,
    n_bins: int,
    seed: int,
    noise_params: Dict,
):
    x, _, z = Expressibility.state_fidelities(
        n_bins=n_bins,
        n_samples=n_samples,
        n_input_samples=n_input_samples,
        seed=seed,
        model=model,
        noise_params=noise_params,
        cache=True,
    )

    y_haar = Expressibility.haar_integral(
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
