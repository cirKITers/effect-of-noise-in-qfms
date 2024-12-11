from kedro.pipeline import Pipeline, node, pipeline

from .nodes import calculate_entanglement


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=calculate_entanglement,
                inputs={
                    "model": "model",
                    "samples": "params:entanglement.n_samples",
                    "noise_params": "params:model.noise_params",
                    "seed": "params:seed",
                },
                outputs="entanglement",
                name="calculate_entanglement",
            ),
        ]
    )
