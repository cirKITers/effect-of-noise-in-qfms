from qml_essentials.model import Model
from qml_essentials.coefficients import Coefficients
from pennylane import Hadamard

from typing import List, Union, Optional
import numpy as np
import mlflow

import logging

log = logging.getLogger(__name__)


def create_model(
    n_qubits: int,
    n_layers: int,
    circuit_type: str,
    data_reupload: bool,
    initialization: str,
    initialization_domain: List[float],
    encoding: str,
    shots: int,
    output_qubit: int,
    seed: int,
    mp_threshold: int,
) -> Model:
    log.info(
        f"Creating model with {n_qubits} qubits, {n_layers} layers, and {circuit_type} circuit."
    )

    if circuit_type[-5:] == "_Plus":
        circuit_type = circuit_type[:-5]
        sp = [lambda wires, **kwargs: Hadamard(wires)]
    else:
        sp = None

    model = Model(
        n_qubits=n_qubits,
        n_layers=n_layers,
        circuit_type=circuit_type,
        data_reupload=data_reupload,
        output_qubit=output_qubit,
        initialization=initialization,
        initialization_domain=initialization_domain,
        shots=shots,
        random_seed=seed,
        state_preparation=sp,
        encoding=encoding,
        mp_threshold=mp_threshold,
    )
    return model


def print_model(model: Model):
    return str(model)


def sample_domain(domain: List[float], omegas: List[List[float]]) -> np.ndarray:
    """
    Generates a flattened grid of (x,y,...) coordinates in a range of -1 to 1.

    Parameters
    ----------
    sidelen : int
        Side length of the grid
    dim : int, optional
        Dimensionality of the grid, by default 2

    Returns
    -------
    np.Tensor
        Grid tensor of shape (sidelen^dim, dim)
    """
    dimensions = 1  # len(omega)

    if isinstance(omegas, int):
        omegas = [o for o in range(omegas + 1)]
    # using the max of all dimensions because we want uniform sampling
    n_d = int(np.ceil(2 * np.max(np.abs(domain)) * np.max(omegas)))

    log.info(f"Using {n_d} data points on {len(omegas)} dimensions")

    tensors = tuple(dimensions * [np.linspace(domain[0], domain[1], num=n_d)])

    return np.meshgrid(*tensors)[0].reshape(-1)  # .reshape(-1, dimensions)


def generate_fourier_series(
    domain_samples: np.ndarray,
    omegas: Union[List[List[float]], int],
    amplitude: Union[float, str],
    seed: Optional[int] = None,
) -> np.ndarray:
    """
    Generates the Fourier series representation of a function.

    Parameters
    ----------
    domain_samples : np.ndarray
        Grid of domain samples.
    omega : Union[List[List[float]], int]
        List of frequencies for each dimension or number of frequencies
    amplitude : Union[float, str]
        "random" or amplitude value for all coefficients
    seed : Optional[int]: seed for random init

    Returns
    -------
    np.ndarray
        Fourier series representation of the function.
    """
    if isinstance(omegas, int):
        omegas = np.arange(-omegas, omegas + 1)
    omegas = np.array(omegas)

    if isinstance(amplitude, float):
        coefficients = [amplitude for _ in omegas]
    elif amplitude == "random":
        rng = np.random.default_rng(seed=seed)
        max_f = max(omegas)
        c_pos = rng.random(max_f) + 1j * rng.random(max_f)
        c_neg = np.conj(c_pos)[::-1]
        c0 = rng.random(1)
        coefficients = np.concatenate([c_neg.T, c0, c_pos.T])
    else:
        raise ValueError("No amplidudes provided")

    values = np.stack(
        [
            Coefficients.evaluate_Fourier_series(coefficients, omegas, x)
            for x in domain_samples
        ]
    )
    norm_factor = np.max(np.abs(values))
    values /= norm_factor
    coefficients /= norm_factor

    mlflow.log_param("target_coefficients_real", coefficients.real.tolist())
    mlflow.log_param("target_coefficients_imag", coefficients.imag.tolist())

    return {
        "fourier_series": values,
        "fourier_coefficients": coefficients,
    }
