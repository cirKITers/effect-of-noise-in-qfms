from kedro.pipeline import Pipeline, node, pipeline

from .nodes import sample_domain, generate_fourier_series


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(
                func=sample_domain,
                inputs={
                    "domain": "params:domain",
                    "omegas": "params:omegas",
                },
                outputs="domain_samples",
                name="sample_domain",
            ),
            node(
                func=generate_fourier_series,
                inputs={
                    "domain_samples": "domain_samples",
                    "omegas": "params:omegas",
                    "coefficients": "params:coefficients",
                },
                outputs="fourier_series",
                name="generate_fourier_series",
            ),
        ]
    )
