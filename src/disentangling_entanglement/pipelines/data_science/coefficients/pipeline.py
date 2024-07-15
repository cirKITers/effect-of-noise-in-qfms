from kedro.pipeline import Pipeline, node, pipeline

from .nodes import iterate_layers_and_noise


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=iterate_layers_and_noise,
                inputs={
                    "model": "model",
                    "noise_params": "params:noise_params",
                    "noise_steps": "params:noise_steps",
                    "samples": "params:coefficients_n_samples",
                },
                outputs=None,
                name="calculate_coefficients",
            ),
        ]
    )
