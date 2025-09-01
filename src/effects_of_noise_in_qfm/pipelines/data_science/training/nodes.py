from qml_essentials.entanglement import Entanglement
from qml_essentials.coefficients import Coefficients
from qml_essentials.model import Model
from qml_essentials.ansaetze import Gates

import pennylane as qml
import pennylane.numpy as np
import mlflow
from typing import Dict, Tuple, Callable
from rich.progress import track
import pandas as pd

import logging

from effects_of_noise_in_qfm.helpers.utils import NoiseDict

log = logging.getLogger(__name__)


def validate_problem(omegas: int, model: Model):
    """
    Checks if the complexity of a given model is appropriate to do a regression
    task on a Fourier series.

    Args:
        omegas (int): The number of frequencies in the target Fourier series.
        model (Model): The function approximating model.
    """
    if model.n_layers == 1 or model.n_qubits == 1:
        if model.degree < omegas:
            log.warning(
                f"Model is too small to use {omegas} frequencies. Consider adjusting the model degree."
            )
        elif model.degree > omegas:
            log.warning(
                f"Model is too large to use {omegas} frequencies. Consider adjusting the model degree."
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

    Args:
        opt (qml.GradientDescentOptimizer): PennyLane Optimiser.
        objective_fn (Callable): The objective function for optimisation.

    Returns:
        Tuple[np.ndarray, float, np.ndarray]:
            - The new variable values :math:`x^{(t+1)}`.
            - The objective function output prior to the step.
            - The gradients.
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
    fourier_coefficients: np.ndarray,
    noise_params: Dict,
    steps: int,
    learning_rate: float,
    convergence_threshold: float,
    convergence_gradient: float,
    convergence_steps: int,
) -> Dict[str, pd.DataFrame]:
    """
    Train a given model on the regression task of a target Fourier series.

    Args:
        model (Model): The function approximating model.
        domain_samples (np.ndarray): The inputs to the training task.
        fourier_series (np.ndarray): The target values (solutions) of the FS to
            be learned.
        fourier_coefficients (np.ndarray): The actual values for the Fourier
            coefficients in the target FS.
        noise_params (Dict): Noise parameters for the model if training with
            noise.
        steps (int): Number of training steps.
        learning_rate (float): Optimiser learning rate.
        convergence_threshold (float): Threshold for early stopping. Set to -1
            to disable.
        convergence_gradient (float): Gradient early stopping threshold. Set to
            -1 to disable.
        convergence_steps (int): Number of steps over which the gradient is
            checked if convergence_gradient is set.

    Returns:
        Dict[str, pd.DataFrame]: Result dict containing the following:
            - "params": Parameter at each step.
            - "grads": Gradients at each step.
            - "metrics": Metrics occuring during the training (MSE, FS dist,
                Entanglement, Fourier Coefficients).
    """
    opt = qml.AdamOptimizer(stepsize=learning_rate)

    # Indices for logging params and gradients
    df_param_index_names = ["layer_dim", "param_dim"]
    df_params_index = pd.MultiIndex.from_product(
        [range(s) for s in model.params.shape], names=df_param_index_names
    )
    df_grads_index_names = ["out_dim", "layer_dim", "param_dim"]
    df_grads_index = pd.MultiIndex.from_product(
        [range(s) for s in (1, *model.params.shape)], names=df_grads_index_names
    )
    df_params = pd.DataFrame()
    df_grads = pd.DataFrame()
    df_metrics = pd.DataFrame(
        columns=[
            "step",
            "mse",
            "coeff_dist",
            "entanglement",
            "frequencies",
            "coeffs_real",
            "coeffs_imag",
        ]
    )

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

    log.info(f"Training model for {steps} steps")

    costs = np.zeros(steps)

    # HACK
    pqc = model.pqc

    def pqc_no_batch_gate_error(*args, **kwargs):
        Gates.batch_gate_error = False
        ret = pqc(*args, **kwargs)
        Gates.batch_gate_error = True
        return ret

    for step in track(range(steps), description="Training..", total=steps):
        df_metrics.loc[step, "step"] = step

        # log entanglement
        ent_cap = Entanglement.entanglement_of_formation(
            model=model,
            n_samples=0,  # disable sampling, use model params
            seed=None,  # set seed none to disable warnings
            noise_params=noise_params,
            cache=False,
        )
        log.debug(f"Entangling capability in step {step}: {ent_cap}")
        mlflow.log_metric("entangling_capability", ent_cap, step)
        df_metrics.loc[step, "entanglement"] = ent_cap

        # HACK
        model.pqc = pqc_no_batch_gate_error
        # log coefficients
        coeffs, freqs = Coefficients.get_spectrum(
            model=model,
            shift=True,
            trim=True,
            noise_params=noise_params,
            cache=False,
        )
        # HACK
        model.pqc = pqc

        dist = np.sum(np.abs(coeffs - fourier_coefficients))
        log.debug(f"Coefficients dist: {dist}")
        df_metrics.loc[step, "coeff_dist"] = dist

        if model.n_input_feat == 1:
            coeffs = coeffs[len(coeffs) // 2 :]
            freqs = freqs[len(freqs) // 2 :]
        else:
            freqs = np.stack(np.meshgrid(*[freqs] * model.n_input_feat)).T.reshape(
                *coeffs.shape, model.n_input_feat
            )

        log.debug(f"Frequencies in step {step}: {freqs}")
        log.debug(f"Coefficients in step {step}: {coeffs}")

        df_metrics.loc[step, "frequencies"] = freqs.tolist()
        df_metrics.loc[step, "coeffs_real"] = np.array(coeffs).T.real.tolist()
        df_metrics.loc[step, "coeffs_imag"] = np.array(coeffs).T.imag.tolist()

        # actual training step
        model.params, cost_val, grads = step_cost_and_grads(
            opt,
            cost,
            model.params,
            inputs=domain_samples,
            noise_params=noise_params,
            cache=False,  # disable caching because currently no gradients are being stored
            execution_type="expval",
            force_mean=True,
        )

        # log params and gradients
        df_params = pd.concat(
            [
                df_params,
                pd.DataFrame(
                    {"param": model.params.flatten(), "step": step},
                    index=df_params_index,
                ),
            ]
        )
        df_grads = pd.concat(
            [
                df_grads,
                pd.DataFrame(
                    {"param": grads[0].flatten(), "step": step},
                    index=df_grads_index,
                ),
            ]
        )

        # log cost
        log.debug(f"Cost in step {step}: {cost_val}")
        mlflow.log_metric("mse", cost_val, step)
        df_metrics.loc[step, "mse"] = cost_val
        costs[step] = cost_val

        # log control parameters
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

            mlflow.log_metric("control_rotation_mean", control_rotation_mean, step)

        # early stopping
        if cost_val < convergence_threshold:
            log.info(
                f"Convergence threshold {convergence_threshold} reached after {step} steps."
            )
            break
        elif (
            step >= convergence_steps
            and np.abs(np.gradient(costs)[step - convergence_steps : step].mean())
            < convergence_gradient
        ):
            log.info(
                f"Convergence gradient {convergence_gradient} reached after {step} steps."
            )
            break

    # Convert indices to columns
    df_params = df_params.rename_axis(df_param_index_names).reset_index()
    df_grads = df_grads.rename_axis(df_grads_index_names).reset_index()

    return {
        "params": df_params,
        "grads": df_grads,
        "metrics": df_metrics,
    }


def iterate_noise(
    model: Model,
    domain_samples: np.ndarray,
    fourier_series: np.ndarray,
    fourier_coefficients: np.ndarray,
    noise_params: Dict,
    noise_steps: int,
    steps: int,
    learning_rate: float,
    convergence_threshold: float,
    convergence_gradient: float,
    convergence_steps: int,
    seed: int,
):
    """
    Iterate over different noise levels and train a given model on the
    regression task of a target Fourier series. for each level using the noise
    parameters.

    Args:
        model (Model): The function approximating model.
        domain_samples (np.ndarray): The inputs to the training task.
        fourier_series (np.ndarray): The target values (solutions) of the FS to
            be learned.
        fourier_coefficients (np.ndarray): The actual values for the Fourier
            coefficients in the target FS.
        noise_params (Dict): A dictionary of noise parameters with their
            initial values.
        noise_steps (int): The number of steps to incrementally apply noise.
        steps (int): Number of training steps.
        learning_rate (float): Optimiser learning rate.
        convergence_threshold (float): Threshold for early stopping. Set to -1
            to disable.
        convergence_gradient (float): Gradient early stopping threshold. Set to
            -1 to disable.
        convergence_steps (int): Number of steps over which the gradient is
            checked if convergence_gradient is set.
        seed (int): Seed for model initialisation each noise param iteration.

    Returns:
        Dict[str, pd.DataFrame]: Result dict containing the following for all
        noise levels:
            - "params": Parameter at each step.
            - "grads": Gradients at each step.
            - "metrics": Metrics occuring during the training (MSE, FS dist,
                Entanglement, Fourier Coefficients).
    """
    noise_params = NoiseDict(noise_params)
    noise_columns_df = [
        *[n for n in noise_params.keys()],
        "noise_level",
    ]

    df_params = pd.DataFrame(columns=noise_columns_df)
    df_grads = pd.DataFrame(columns=noise_columns_df)
    df_metrics = pd.DataFrame(columns=noise_columns_df)

    for step in range(noise_steps + 1):  # +1 to go for 100%
        part_noise_params = noise_params * (step / noise_steps)

        # Reset Model
        model.initialize_params(np.random.default_rng(seed))
        res = train_model(
            model,
            domain_samples,
            fourier_series,
            fourier_coefficients,
            part_noise_params,
            steps,
            learning_rate,
            convergence_threshold,
            convergence_gradient,
            convergence_steps,
        )

        # Add noise data to dfs
        for df_name in ["params", "grads", "metrics"]:
            res[df_name]["noise_step"] = step
            res[df_name]["noise_level"] = step / noise_steps
            for n, v in part_noise_params.items():
                res[df_name][n] = v
        df_params = pd.concat([df_params, res["params"]])
        df_grads = pd.concat([df_grads, res["grads"]])
        df_metrics = pd.concat([df_metrics, res["metrics"]])

    return {
        "params": df_params,
        "grads": df_grads,
        "metrics": df_metrics,
    }
