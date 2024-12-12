from kedro.pipeline import Pipeline, node, pipeline

from .nodes import calculate_entanglement, iterate_noise


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
            node(
                func=iterate_noise,
                inputs={
                    "model": "model",
                    "noise_params": "params:model.noise_params",
                    "noise_steps": "params:model.noise_steps",
                    "n_samples": "params:entanglement.n_samples",
                    "seed": "params:seed",
                },
                outputs={"entangling_capability_noise": "entangling_capability_noise"},
                name="entanglement_iterate_noise",
            ),
        ]
    )
