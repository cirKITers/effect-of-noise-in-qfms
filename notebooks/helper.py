import plotly
import re
import json
import hashlib
import pandas as pd
import mlflow
import numpy as np
import os
from rich.progress import track


def save_fig(fig, name, run_ids, experiment_id):
    hs = generate_hash(run_ids)
    path = f"results/{experiment_id}/{hs}/"
    os.makedirs(path, exist_ok=True)
    print(f"Saving figure to {path}{name}.png")
    fig.write_image(f"{path}{name}.png")


def get_color_iterator():
    main_colors_it = iter(plotly.colors.qualitative.Dark2)
    sec_colors_it = iter(plotly.colors.qualitative.Pastel2)

    return main_colors_it, sec_colors_it


def generate_hash(run_ids):
    hs = hashlib.md5(repr(run_ids).encode("utf-8")).hexdigest()
    return hs


def read_from_html(path):
    with open(path) as f:
        html = f.read()
    call_arg_str = re.findall(r"Plotly\.newPlot\((.*)\)", html[-(2**16) :])[0]
    call_args = json.loads(f"[{call_arg_str}]")
    plotly_json = {"data": call_args[1], "layout": call_args[2]}

    return plotly.io.from_json(json.dumps(plotly_json))


def read_from_csv(path):
    return pd.read_csv(path)


def rgb_to_rgba(rgb_value: str, alpha: float):
    """
    Adds the alpha channel to an RGB Value and returns it as an RGBA Value
    :param rgb_value: Input RGB Value
    :param alpha: Alpha Value to add  in range [0,1]
    :return: RGBA Value
    """
    return f"rgba{rgb_value[3:-1]}, {alpha})"


def get_training_df(run_ids):
    df = pd.DataFrame(
        columns=[
            "run_id",
            "ansatz",
            "qubits",
            "seed",
            "mse",
            "steps",
        ]
    )

    for it, run_id in track(
        enumerate(run_ids), description="Collecting training data..", total=len(run_ids)
    ):
        client = mlflow.tracking.MlflowClient()
        if client.get_run(run_id).info.status != "FINISHED":
            print(f"Run {run_id} not finished")
            continue

        df.loc[it, "run_id"] = run_id
        df.loc[it, "ansatz"] = client.get_run(run_id).data.params["model.circuit_type"]
        df.loc[it, "qubits"] = int(client.get_run(run_id).data.params["model.n_qubits"])
        df.loc[it, "seed"] = int(client.get_run(run_id).data.params["seed"])
        steps = int(client.get_run(run_id).data.params["training.steps"])

        mse_hist = client.get_metric_history(run_id, "mse")
        mse_values = np.empty((steps))
        mse_values[:] = np.nan

        mse_values[: len(mse_hist)] = [entity.value for entity in mse_hist]

        df.loc[it, "mse"] = mse_values
        df.loc[it, "steps"] = len(mse_hist)

    return df


def get_csv_artifact(run_id, identifier=""):
    client = mlflow.tracking.MlflowClient()

    csv_path = client.download_artifacts(run_id, f"{identifier}.csv", "./")
    df = read_from_csv(csv_path)

    os.remove(csv_path)

    return df


def get_plotly_artifact(run_id, identifier=""):
    client = mlflow.tracking.MlflowClient()

    sub_fig_path = client.download_artifacts(run_id, f"{identifier}.html", "./")
    sub_fig = read_from_html(sub_fig_path)
    sub_fig_trace = sub_fig.data[0]
    sub_fig_trace.update(
        # coloraxis=f"coloraxis",
        zmax=1.0,
        zmin=0.0,
    )

    os.remove(sub_fig_path)

    return sub_fig_trace


def get_expressibility_df(run_ids):
    df = pd.DataFrame(
        columns=[
            "run_id",
            "ansatz",
            "qubits",
            "seed",
            "BitFlip",
            "PhaseFlip",
            "AmplitudeDamping",
            "PhaseDamping",
            "Depolarizing",
            "expressibility",
        ]
    )

    for it, run_id in track(
        enumerate(run_ids),
        description="Collecting coefficients data..",
        total=len(run_ids),
    ):
        client = mlflow.tracking.MlflowClient()
        if client.get_run(run_id).info.status != "FINISHED":
            print(f"Run {run_id} not finished")
            continue

        sub_df_a = pd.DataFrame(
            columns=[
                "run_id",
                "ansatz",
                "qubits",
                "seed",
            ]
        )

        sub_df_a.loc[it, "run_id"] = run_id

        sub_df_a.loc[it, "ansatz"] = client.get_run(run_id).data.params[
            "model.circuit_type"
        ]
        sub_df_a.loc[it, "qubits"] = int(
            client.get_run(run_id).data.params["model.n_qubits"]
        )

        sub_df_a.loc[it, "seed"] = int(client.get_run(run_id).data.params["seed"])

        sub_df_b = get_csv_artifact(run_id, "expressibility_noise")
        df = pd.concat(
            [df, pd.merge(sub_df_a.iloc[[-1]], sub_df_b, how="cross")]
        ).reset_index(drop=True)

    return df


def assign_ansatz_id(df):
    # add a column with name "ansatz_id" where each ansatz has a unique id
    df["ansatz_id"] = df["ansatz"].factorize()[0]
    return df
