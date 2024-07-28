from disentangling_entanglement.helpers.entanglement import Entanglement
from qml_essentials.model import Model

import pennylane as qml
import pennylane.numpy as np
import mlflow
from typing import Dict, List, Tuple, Callable
from rich.progress import track

import logging

log = logging.getLogger(__name__)


def validate_problem(omegas: List[List[float]], model: Model):
    if model.n_layers == 1 or model.n_qubits == 1:
        if model.degree < len(omegas):
            log.warning(
                f"Model is too small to use {len(omegas)} frequencies. Consider adjusting the model degree."
            )
        elif model.degree > len(omegas):
            log.warning(
                f"Model is too large to use {len(omegas)} frequencies. Consider adjusting the model degree."
            )
        else:
            log.info("Problem and model validation passed.")
    else:
        log.warning("Problem validation not implemented yet.")


## TODO: move to qml_essentials
def step_cost_and_grads(
        opt: qml.GradientDescentOptimizer, objective_fn: Callable, *args, **kwargs
) -> Tuple[np.ndarray, float, np.ndarray]:
    """
    Same as qml.GradientDescentOptimizer.step_and_cost but with returning the
    gradients

    Update trainable arguments with one step of the optimizer and return the
    corresponding objective function value prior to the step.

    :param opt: pennylane optimiser
    :type opt: qml.GradientDescentOptimizer
    :param objective_fn: the objective function for optimization
    :type objective_fn: Callable
    :param *args : variable length argument list for objective function
    :param **kwargs : variable length of keyword arguments for the objective
        function
    :return: the new variable values :math:`x^{(t+1)}`
    :return: the objective function output prior to the step
    :return: the gradients
    :rtype: Tuple[np.ndarray, float, np.ndarray]
    """
    g, forward = opt.compute_grad(objective_fn, args, kwargs)
    new_args = opt.apply_grad(g, args)

    if forward is None:
        forward = objective_fn(*args, **kwargs)

    # unwrap from list if one argument, cleaner return
    if len(new_args) == 1:
        return new_args[0], forward, g
    return new_args, forward, g


def train_model(
    model: Model,
    domain_samples: np.ndarray,
    fourier_series: np.ndarray,
    noise_params: Dict,
    epochs: int,
    learning_rate: float,
    batch_size: int,
):
    opt = qml.AdamOptimizer(stepsize=learning_rate)

    def mse(prediction, target):
        return np.mean((prediction - target) ** 2)

    def cost(params, **kwargs):
        prediction = model(params=params, **kwargs)
        if model.execution_type == "probs":
            # convert probabilities for zero state to expectation value
            raise NotImplementedError(
                f"Not implemented gradient calculation for execeution_type "
                f"{model.execution_type} in conjunction with shots."
            )
            prediction = 2 * prediction[:, 0] - 1
        elif isinstance(model.output_qubit, list):
            prediction = np.mean(prediction, axis=0)
        return mse(prediction, fourier_series)

    log.info(f"Training model for {epochs} epochs")

    for epoch in track(range(epochs), description="Training..", total=epochs):
        ent_cap = Entanglement.meyer_wallach(
            model=model,
            samples=0,  # disable sampling, use model params
            inputs=None,
            noise_params=noise_params,
            cache=False,
            execution_type="density",
        )
        log.debug(f"Entangling capability in epoch {epoch}: {ent_cap}")
        mlflow.log_metric("entangling_capability", ent_cap, epoch)

        model.params, cost_val, grads = step_cost_and_grads(
            opt,
            cost,
            model.params,
            inputs=domain_samples,
            noise_params=noise_params,
            cache=False,  # disable caching because currently no gradients are being stored
            execution_type="probs" if model.shots is not None else "expval",
        )

        log.debug(f"Cost in epoch {epoch}: {cost_val}")
        mlflow.log_metric("mse", cost_val, epoch)
        mlflow.log_metrics(
            {
                f"param_l{l:02d}_w{w:02d}": p.numpy()
                for l, par in enumerate(model.params)
                for w, p in enumerate(par)
            },
            step=epoch,
        )
        mlflow.log_metrics(
            {
                f"grad_l{l:02d}_w{w:02d}_g{i:02d}": g
                for l, par in enumerate(grads)
                for w, p in enumerate(par)
                for i, g in enumerate(p)
            },
            step=epoch,
        )


        control_params = np.array(
            [
                model.pqc.get_control_angles(params, model.n_qubits)
                for params in model.params
            ]
        )
        indices = model.pqc.get_control_indices(model.n_qubits)
        if indices is not None:
            control_params = model.params[:, indices[0] : indices[1] : indices[2]]
            control_rotation_mean = (
                np.sum(np.abs(control_params) % (2 * np.pi)) / control_params.size
            )

            mlflow.log_metric("control_rotation_mean", control_rotation_mean, epoch)

    return model
