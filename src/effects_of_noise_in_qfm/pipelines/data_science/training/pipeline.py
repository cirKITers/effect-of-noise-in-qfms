from kedro.pipeline import Pipeline, node, pipeline

from .nodes import validate_problem, train_model, iterate_noise


def create_noise_iteration_pipeline() -> Pipeline:
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
                func=iterate_noise,
                inputs={
                    "model": "model",
                    "domain_samples": "domain_samples",
                    "fourier_series": "fourier_series",
                    "fourier_coefficients": "fourier_coefficients",
                    "noise_params": "params:model.noise_params",
                    "noise_steps": "params:model.noise_steps",
                    "steps": "params:training.steps",
                    "learning_rate": "params:training.learning_rate",
                    "convergence_threshold": "params:training.convergence.threshold",
                    "convergence_gradient": "params:training.convergence.gradient",
                    "convergence_steps": "params:training.convergence.steps",
                    "seed": "params:seed",
                },
                outputs={
                    "params": "trained_params",
                    "grads": "trained_grads",
                    "metrics": "trained_metrics",
                },
                name="iterate_noise_and_train_model",
            ),
        ]
    )


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
                    "fourier_coefficients": "fourier_coefficients",
                    "noise_params": "params:model.noise_params",
                    "steps": "params:training.steps",
                    "learning_rate": "params:training.learning_rate",
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
