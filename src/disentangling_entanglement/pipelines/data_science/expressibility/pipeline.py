from kedro.pipeline import Pipeline, node, pipeline

from .nodes import calculate_expressibility, iterate_noise


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=calculate_expressibility,
                inputs={
                    "model": "model",
                    "n_bins": "params:expressibility.n_bins",
                    "n_samples": "params:expressibility.n_samples",
                    "input_domain": "params:data.domain",
                    "n_input_samples": "params:expressibility.n_input_samples",
                    "noise_params": "params:model.noise_params",
                    "seed": "params:seed",
                },
                outputs="expressibility",
                name="calculate_expressibility",
            ),
            node(
                func=iterate_noise,
                inputs={
                    "model": "model",
                    "noise_params": "params:model.noise_params",
                    "noise_steps": "params:model.noise_steps",
                    "n_samples": "params:expressibility.n_samples",
                    "n_bins": "params:expressibility.n_bins",
                    "seed": "params:seed",
                },
                outputs={"expressibility_noise": "expressibility_noise"},
                name="expressibility_iterate_noise",
            ),
        ]
    )
