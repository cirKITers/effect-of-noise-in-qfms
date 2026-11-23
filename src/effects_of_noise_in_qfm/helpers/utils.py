from typing import Dict, List, Optional, Tuple
from copy import copy

import numpy as np


def input_grid(
    model, n_inputs: int, domain: Optional[List[float]]
) -> Tuple[np.ndarray, List[np.ndarray]]:
    """
    Evenly spaced inputs over one period of the data domain for the descriptor
    experiments with fixed inputs.

    The grid has ``n_inputs`` points on ``[domain[0], domain[1])``.
    Every input is replicated over all input features.

    Args:
        model: The quantum model (provides ``n_input_feat``).
        n_inputs (int): Number of grid points.
        domain (Optional[List[float]]): Input domain; defaults to [-pi, pi].

    Returns:
        Tuple[np.ndarray, List[np.ndarray]]: The grid values of shape
        (n_inputs,) and the corresponding model inputs, each of shape
        (1, n_input_feat).
    """
    if domain is None:
        domain = [-np.pi, np.pi]
    xs = np.linspace(domain[0], domain[1], num=n_inputs, endpoint=False)
    return xs, [np.full((1, model.n_input_feat), x) for x in xs]


class NoiseDict(Dict[str, float]):
    """
    A dictionary subclass for noise params.
    """

    def __truediv__(self, other: float) -> "NoiseDict":
        """
        Divide all values by a scalar.
        """
        noise = {k: v / other for k, v in self.items() if k != "ThermalRelaxation"}
        tr = copy(self["ThermalRelaxation"])
        if tr and isinstance(tr, dict):
            tr["f_factor"] /= other
        noise.update({"ThermalRelaxation": tr})
        return NoiseDict(noise)

    def __mul__(self, other: float) -> "NoiseDict":
        """
        Multiply all values by a scalar.
        """
        noise = {k: v * other for k, v in self.items() if k != "ThermalRelaxation"}
        tr = copy(self["ThermalRelaxation"])
        if tr and isinstance(tr, dict):
            tr["t_factor"] *= other
        noise.update({"ThermalRelaxation": tr})
        return NoiseDict(noise)
