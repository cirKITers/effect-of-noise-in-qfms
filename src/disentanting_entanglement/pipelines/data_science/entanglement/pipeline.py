from kedro.pipeline import Pipeline, node, pipeline

from .nodes import foo


def create_pipeline() -> Pipeline:
    return pipeline(
        [
            node(func=foo, inputs={"": ""}, outputs={"": ""}, name="pass"),
        ]
    )
