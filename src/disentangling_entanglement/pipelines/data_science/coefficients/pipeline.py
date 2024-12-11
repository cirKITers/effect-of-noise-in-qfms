from kedro.pipeline import Pipeline, node, pipeline

from .nodes import iterate_noise_and_layers


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=iterate_noise_and_layers,
                inputs={
                    "model": "model",
                    "noise_params": "params:model.noise_params",
                    "noise_steps": "params:model.noise_steps",
                    "samples": "params:coefficients.n_samples",
                },
                outputs={"coefficients_noise_layers": "coefficients_noise_layers"},
                name="calculate_coefficients",
            ),
        ]
    )
