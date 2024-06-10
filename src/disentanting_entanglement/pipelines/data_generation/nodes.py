from typing import List
import numpy as np

import logging

log = logging.getLogger(__name__)


def sample_domain(domain: List[float], omega: List[List[float]]) -> np.ndarray:
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
    dimensions = len(omega)

    # using the max of all dimensions because we want uniform sampling
    n_d = int(np.ceil(2 * np.max(np.abs(domain)) * np.max(omega)))

    log.info(f"Using {n_d} data points on {len(omega)} dimensions")

    tensors = tuple(dimensions * [np.linspace(domain[0], domain[1], num=n_d)])

    return np.meshgrid(*tensors)[0].reshape(-1, dimensions)


def generate_fourier_series(
    domain_samples: np.ndarray,
    omega: List[List[float]],
) -> np.ndarray:
    """
    Generates the Fourier series representation of a function.

    Parameters
    ----------
    domain_samples : np.ndarray
        Grid of domain samples.
    omega : List[List[float]]
        List of frequencies for each dimension.

    Returns
    -------
    np.ndarray
        Fourier series representation of the function.
    """
    omega = np.array(omega)

    def y(x: np.ndarray) -> float:
        """
        Calculates the Fourier series representation of a function at a given point.

        Parameters
        ----------
        x : np.ndarray
            Point at which to evaluate the function.

        Returns
        -------
        float
            Value of the Fourier series representation at the given point.
        """
        return 1 / np.linalg.norm(omega) * np.sum(np.cos(omega.T * x))  # transpose!

    values = np.stack([y(x) for x in domain_samples])

    return values
