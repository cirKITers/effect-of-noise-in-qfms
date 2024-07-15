"""Project pipelines."""

from typing import Dict

from kedro.framework.project import find_pipelines
from kedro.pipeline import Pipeline

from disentangling_entanglement.pipelines.data_generation.pipeline import (
    create_pipeline as create_data_generation_pipeline,
)
from disentangling_entanglement.pipelines.data_science.entanglement.pipeline import (
    create_pipeline as create_entanglement_pipeline,
)
from disentangling_entanglement.pipelines.data_science.training.pipeline import (
    create_pipeline as create_training_pipeline,
)
from disentangling_entanglement.pipelines.data_science.expressibility.pipeline import (
    create_pipeline as create_expressibility_pipeline,
)
from disentangling_entanglement.pipelines.data_science.coefficients.pipeline import (
    create_pipeline as create_coefficients_pipeline,
)

# from disentangling_entanglement.pipelines.visualization.pipeline import (
#     create_pipeline as create_visualization_pipeline,
# )


def register_pipelines() -> Dict[str, Pipeline]:
    """Register the project's pipelines.

    Returns:
        A mapping from pipeline names to ``Pipeline`` objects.
    """
    pipelines = {
        "__default__": create_data_generation_pipeline()
        + create_entanglement_pipeline()
        + create_expressibility_pipeline()
        + create_training_pipeline(),
        "training": create_data_generation_pipeline() + create_training_pipeline(),
        "coefficients": create_data_generation_pipeline()
        + create_coefficients_pipeline(),
        "entanglement": create_data_generation_pipeline()
        + create_entanglement_pipeline(),
        "expressibility": create_data_generation_pipeline()
        + create_expressibility_pipeline(),
    }
    return pipelines
