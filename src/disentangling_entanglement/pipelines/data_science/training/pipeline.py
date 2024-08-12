from kedro.pipeline import Pipeline, node, pipeline

from .nodes import validate_problem, train_model


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=validate_problem,
                inputs={
                    "omegas": "params:omegas",
                    "model": "model",
                },
                outputs=None,
                name="validate_problem",
            ),
            node(
                func=train_model,
                inputs={
                    "model": "model",
                    "domain_samples": "domain_samples",
                    "fourier_series": "fourier_series",
                    "noise_params": "params:noise_params",
                    "epochs": "params:epochs",
                    "learning_rate": "params:learning_rate",
                    "batch_size": "params:batch_size",
                },
                outputs={
                    "model": "trained_model",
                    "params": "trained_params",
                    "grads": "trained_grads",
                },
                name="train_model",
            ),
        ]
    )
