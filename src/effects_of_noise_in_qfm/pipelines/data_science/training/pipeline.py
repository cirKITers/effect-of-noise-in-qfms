from kedro.pipeline import Pipeline, node, pipeline

from .nodes import validate_problem, train_model


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=validate_problem,
                inputs={
                    "omegas": "params:data.omegas",
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
                    "noise_params": "params:model.noise_params",
                    "steps": "params:training.steps",
                    "learning_rate": "params:training.learning_rate",
                    "batch_size": "params:training.batch_size",
                    "convergence_threshold": "params:training.convergence.threshold",
                    "convergence_gradient": "params:training.convergence.gradient",
                    "convergence_steps": "params:training.convergence.steps",
                },
                outputs={
                    "model": "trained_model",
                    "params": "trained_params",
                    "grads": "trained_grads",
                    "metrics": "trained_metrics",
                },
                name="train_model",
            ),
        ]
    )
