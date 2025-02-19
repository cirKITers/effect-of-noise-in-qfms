import plotly
from plotly.validators.scatter.marker import SymbolValidator
import re
import json
import hashlib
import pandas as pd
import mlflow
import numpy as np
import os
from rich.progress import track
from typing import Union, List


def save_fig(fig, name, run_ids, experiment_id, font_size=16, scale=1):
    hs = generate_hash(run_ids)
    path = f"results/{experiment_id}/{hs}/"
    os.makedirs(path, exist_ok=True)
    print(f"Saving figure to {path}{name}.pdf")
    fig.update_layout(font=dict(size=font_size))
    fig.write_image(f"{path}{name}.pdf", scale=scale)


def get_qual_color_iterator():
    main_colors_it = iter(plotly.colors.qualitative.Dark2)
    sec_colors_it = iter(plotly.colors.qualitative.Pastel2)

    return main_colors_it, sec_colors_it


def get_seq_color_iterator(n=10):
    return iter(plotly.colors.sample_colorscale(plotly.colors.sequential.Emrld, n))


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


def read_from_csv(path, **kwargs):
    return pd.read_csv(path, **kwargs)


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


def get_csv_artifact(run_id, identifier: str, **kwargs):
    client = mlflow.tracking.MlflowClient()

    csv_path = client.download_artifacts(run_id, f"{identifier}.csv", "./")
    df = read_from_csv(csv_path, **kwargs)

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


def get_entanglement_df(run_ids):
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
            "entangling_capability",
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

        sub_df_b = get_csv_artifact(run_id, "entangling_capability_noise")
        df = pd.concat(
            [df, pd.merge(sub_df_a.iloc[[-1]], sub_df_b, how="cross")]
        ).reset_index(drop=True)

    return df


def get_symbol_iterator():
    raw_symbols = SymbolValidator().values
    symbols = []
    for i in range(0, len(raw_symbols), 12):
        symbols.append(raw_symbols[i])

    return iter(symbols)


def get_coeffs_df(run_ids):
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
            "coeffs_abs_var",
            "coeffs_abs_mean",
        ]
    )

    def converter(s):
        s = s.replace("\n", "")
        s = s.replace("[", "")
        s = s.replace("]", "")
        return np.fromstring(s, dtype=float, sep=" ")

    def mean_converter(s):
        values = converter(s)
        return np.mean(values)

    def var_converter(s):
        values = converter(s)
        return np.mean(values)

    print(
        "\nThis a hint that there is some very inefficient code.. :) Checkout a xkcd comic while waiting: https://c.xkcd.com/random/comic/\n"
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

        try:
            sub_df_b = get_csv_artifact(
                run_id,
                "coefficients_noise",
                converters={
                    "coeffs_abs_mean": converter,
                    "coeffs_abs_var": converter,
                    "frequencies": converter,
                },
            )
        except:
            print(f"No coefficients for run {run_id}")
            sub_df_b = pd.DataFrame()

        df = pd.concat(
            [df, pd.merge(sub_df_a.iloc[[-1]], sub_df_b, how="cross")]
        ).reset_index(drop=True)

    return df


def expand_coeffs(df, metric):

    qubits = sorted(df.qubits.unique())
    n_qubits = max(qubits)

    # for freq in range(n_qubits + 1):
    #     df[f"{metric}_{freq}"] = np.nan

    for idx in df.index:
        for freq in range(df.loc[idx, metric].size):
            df.loc[idx, f"{metric}_{freq}"] = df.loc[idx, metric][freq].item()

    return df


def assign_ansatz_id(df):
    # add a column with name "ansatz_id" where each ansatz has a unique id
    df["ansatz_id"] = df["ansatz"].factorize()[0]
    return df
