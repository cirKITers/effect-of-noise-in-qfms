from typing import Dict
import logging
import mlflow

from disentangling_entanglement.helpers.expressibility import (
    Expressibility_Sampler,
    get_sampled_haar_probability_histogram,
    get_kl_divergence_expr,
)
from qml_essentials.model import Model


log = logging.getLogger(__name__)


def calculate_expressibility(
    model: Model,
    n_samples: int,
    n_input_samples: int,
    n_bins: int,
    seed: int,
    noise_params: Dict,
):

    expr_sampler = Expressibility_Sampler(
        model=model,
        n_samples=n_samples,
        n_input_samples=n_input_samples,
        seed=seed,
        noise_params=noise_params,
        cache=True,
        execution_type="density",
    )

    x, y, z = expr_sampler.sample_hist_state_fidelities(n_bins=n_bins)

    _, y_haar = get_sampled_haar_probability_histogram(
        model.n_qubits,
        n_bins,
    )

    kl_divergence = get_kl_divergence_expr(z, y_haar)
    log.debug(f"KL Divergence {kl_divergence}")

    for i, prob in enumerate(y_haar):
        mlflow.log_metric("haar_probability", prob, i)

    for i, (x_sample, kl) in enumerate(zip(x, kl_divergence)):
        mlflow.log_metric("kl_divergence", kl, i)
        mlflow.log_metric("x", x_sample, i)

        for j, fidelity in enumerate(z[i]):
            mlflow.log_metric(f"x_{x_sample:.2f}_fidelity", fidelity, j)

    return kl_divergence
