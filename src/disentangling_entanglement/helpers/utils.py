from typing import Dict
from copy import copy


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
