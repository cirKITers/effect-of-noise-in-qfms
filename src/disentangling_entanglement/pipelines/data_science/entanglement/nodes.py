from disentangling_entanglement.helpers.entanglement import Entanglement
from disentangling_entanglement.helpers.model import Model

from typing import Dict

import logging

log = logging.getLogger(__name__)


def create_model(
    n_qubits: int, n_layers: int, circuit_type: str, data_reupload: bool
) -> Model:
    return Model(n_qubits, n_layers, circuit_type, data_reupload)


def calculate_entanglement(model: Model, samples: int, seed: int, noise_params: Dict):

    entangling_capability = Entanglement.meyer_wallach(
        model=model,
        samples=samples,
        seed=seed,
        inputs=[0],
        noise_params=noise_params,
        cache=True,
        state_vector=True,
    )

    log.info(f"Calculated entangling capability: {entangling_capability}")

    return entangling_capability
