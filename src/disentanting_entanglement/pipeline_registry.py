"""Project pipelines."""

from typing import Dict

from kedro.framework.project import find_pipelines
from kedro.pipeline import Pipeline

from disentanting_entanglement.pipelines.data_generation.pipeline import (
    create_pipeline as create_data_generation_pipeline,
)
from disentanting_entanglement.pipelines.data_science.entanglement.pipeline import (
    create_pipeline as create_entanglement_pipeline,
)

# from disentanting_entanglement.pipelines.visualization.pipeline import (
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
    }
    return pipelines
