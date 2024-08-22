from qml_essentials.model import Model
from qml_essentials.entanglement import Entanglement

from typing import Dict

import logging

log = logging.getLogger(__name__)


def calculate_entanglement(model: Model, samples: int, seed: int, noise_params: Dict):

    entangling_capability = Entanglement.meyer_wallach(
        model=model,
        n_samples=samples,
        seed=seed,
        inputs=None,
        noise_params=noise_params,
        cache=True,
        execution_type="density",
    )

    log.info(f"Calculated entangling capability: {entangling_capability}")

    return entangling_capability
