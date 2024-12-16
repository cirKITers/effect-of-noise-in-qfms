from kedro.pipeline import Pipeline, node, pipeline

from .nodes import iterate_noise_and_layers, iterate_noise


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            # node(
            #     func=iterate_noise_and_layers,
            #     inputs={
            #         "model": "model",
            #         "noise_params": "params:model.noise_params",
            #         "noise_steps": "params:model.noise_steps",
            #         "n_samples": "params:coefficients.n_samples",
            #     },
            #     outputs={"coefficients_noise_layers": "coefficients_noise_layers"},
            #     name="coefficients_iterate_noise_and_layers",
            # ),
            node(
                func=iterate_noise,
                inputs={
                    "model": "model",
                    "noise_params": "params:model.noise_params",
                    "noise_steps": "params:model.noise_steps",
                    "n_samples": "params:coefficients.n_samples",
                    "seed": "params:seed",
                },
                outputs={"coefficients_noise": "coefficients_noise"},
                name="coefficients_iterate_noise",
            ),
        ]
    )
