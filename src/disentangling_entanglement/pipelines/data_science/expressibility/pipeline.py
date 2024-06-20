from kedro.pipeline import Pipeline, node, pipeline

from .nodes import calculate_expressibility


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=calculate_expressibility,
                inputs={
                    "model": "model",
                    "n_bins": "params:n_bins",
                    "n_samples": "params:n_samples",
                    "n_input_samples": "params:n_input_samples",
                    "noise_params": "params:noise_params",
                    "seed": "params:seed",
                },
                outputs="expressibility",
                name="calculate_expressibility",
            ),
        ]
    )
