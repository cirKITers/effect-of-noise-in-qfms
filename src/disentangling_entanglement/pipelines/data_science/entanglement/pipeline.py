from kedro.pipeline import Pipeline, node, pipeline

from .nodes import calculate_entanglement


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=calculate_entanglement,
                inputs={
                    "model": "model",
                    "samples": "params:ent_n_samples",
                    "noise_params": "params:noise_params",
                    "seed": "params:seed",
                },
                outputs="entanglement",
                name="calculate_entanglement",
            ),
        ]
    )
