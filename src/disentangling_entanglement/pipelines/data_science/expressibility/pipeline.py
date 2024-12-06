from kedro.pipeline import Pipeline, node, pipeline

from .nodes import calculate_expressibility, iterate_noise


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=calculate_expressibility,
                inputs={
                    "model": "model",
                    "n_bins": "params:expr_n_bins",
                    "n_samples": "params:expr_n_samples",
                    "input_domain": "params:domain",
                    "n_input_samples": "params:expr_n_input_samples",
                    "noise_params": "params:noise_params",
                    "seed": "params:seed",
                },
                outputs="expressibility",
                name="calculate_expressibility",
            ),
            node(
                func=iterate_noise,
                inputs={
                    "model": "model",
                    "noise_params": "params:noise_params",
                    "noise_steps": "params:noise_steps",
                    "n_samples": "params:expr_n_samples",
                    "n_bins": "params:expr_n_bins",
                    "seed": "params:seed",
                },
                outputs={"expressibility_noise": "expressibility_noise"},
                name="iterate_noise",
            ),
        ]
    )
