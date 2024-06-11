from kedro.pipeline import Pipeline, node, pipeline

from .nodes import create_model, calculate_entanglement


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=create_model,
                inputs={
                    "n_qubits": "params:n_qubits",
                    "n_layers": "params:n_layers",
                    "circuit_type": "params:circuit_type",
                    "data_reupload": "params:data_reupload",
                },
                outputs="model",
                name="create_model",
            ),
            node(
                func=calculate_entanglement,
                inputs={
                    "model": "model",
                    "samples": "params:samples",
                    "noise_params": "params:noise_params",
                    "seed": "params:seed",
                },
                outputs="entanglement",
                name="calculate_entanglement",
            ),
        ]
    )
