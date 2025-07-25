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
from typing import Union, List, Optional
import ast
import traceback


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


def get_training_df(run_ids, debug=False):
    columns = [
        "run_id",
        "ansatz",
        "qubits",
        "seed",
        "problem_seed",
        "encoding",
        "BitFlip",
        "PhaseFlip",
        "AmplitudeDamping",
        "PhaseDamping",
        "Depolarizing",
        "StatePreparation",
        "Measurement",
        "GateError",
        "mse",
        "step",
        "coeff_dist",
        "entanglement",
        "original_idx",
        "coeff_idx",
    ]
    array_cols = [
        "coeffs_real",
        "coeffs_imag",
        "frequencies",
    ]
    df = pd.DataFrame(columns=columns + array_cols)

    def list_converter(s):
        return np.array(ast.literal_eval(s), dtype=float)

    all_cfgs = init_all_cfg_dict()

    for it, run_id in track(
        enumerate(run_ids), description="Collecting training data..", total=len(run_ids)
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
                "problem_seed",
            ]
        )

        sub_df_a.loc[it, "run_id"] = run_id

        ansatz = client.get_run(run_id).data.params["model.circuit_type"]
        sub_df_a.loc[it, "ansatz"] = ansatz

        qubits = int(client.get_run(run_id).data.params["model.n_qubits"])
        sub_df_a.loc[it, "qubits"] = qubits

        seed = int(client.get_run(run_id).data.params["seed"])
        sub_df_a.loc[it, "seed"] = seed

        problem_seed = int(client.get_run(run_id).data.params["data.seed"])
        sub_df_a.loc[it, "problem_seed"] = problem_seed

        encoding = client.get_run(run_id).data.params.get("model.encoding", "RX")

        n_input_feat = int(
            client.get_run(run_id).data.params.get("model.n_input_feat", 1)
        )
        if n_input_feat == 2:
            encoding = "RXRY"
        n_input_feat = (
            len(ast.literal_eval(encoding)) if "[" in encoding else n_input_feat
        )
        if encoding == "['RX', 'RY']":
            encoding = "RXRY"
        sub_df_a.loc[it, "encoding"] = encoding
        sub_df_a.loc[it, "n_input_feat"] = n_input_feat

        noise_params = client.get_run(run_id).data.params["model.noise_params"]
        noise = [
            k for k, v in ast.literal_eval(noise_params).items() if float(v) > 0.0
        ][0]
        all_cfgs[ansatz][qubits][seed][noise]["0.03"][encoding][problem_seed] += 1

        converter_dict = {c: list_converter for c in array_cols}

        try:
            sub_df_b = get_csv_artifact(
                run_id,
                "trained_metrics",
                converters=converter_dict,
            )

            for ac in array_cols:
                sub_df_b[ac] = sub_df_b[ac].apply(list)

            sub_df_b["original_idx"] = sub_df_b.index
            sub_df_b = sub_df_b.explode(array_cols, ignore_index=True)
            sub_df_b["coeff_idx"] = sub_df_b.groupby("original_idx").cumcount()

            df = pd.concat(
                [df, pd.merge(sub_df_a.iloc[[-1]], sub_df_b, how="cross")]
            ).reset_index(drop=True)

        except Exception as e:
            print(f"No results for run {run_id}")
            all_cfgs[ansatz][qubits][seed][noise]["0.03"][encoding][problem_seed] -= 1

    if debug:
        check_complete(all_cfgs)

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


def get_expressibility_df(
    run_ids,
    debug=False,
):
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
            "ThermalRelaxation",
            "StatePreparation",
            "Measurement",
            "expressibility",
        ]
    )

    all_cfgs = init_all_cfg_dict()

    for it, run_id in track(
        enumerate(run_ids),
        description="Collecting expressibility data..",
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

        ansatz = client.get_run(run_id).data.params["model.circuit_type"]
        sub_df_a.loc[it, "ansatz"] = ansatz

        qubits = int(client.get_run(run_id).data.params["model.n_qubits"])
        sub_df_a.loc[it, "qubits"] = qubits

        noise_params = client.get_run(run_id).data.params["model.noise_params"]
        noise = [k for k, v in ast.literal_eval(noise_params).items() if float(v) > 0.0]
        if len(noise) > 0:
            noise = noise[0]
        else:
            noise = "noiseless"

        seed = client.get_run(run_id).data.params["seed"]

        noise_value = [
            v for k, v in ast.literal_eval(noise_params).items() if float(v) > 0.0
        ]
        if len(noise_value) > 0:
            noise_value = noise_value[0]
        else:
            noise_value = 0
        if seed is None or seed == "None":
            continue
        seed = int(seed)
        sub_df_a.loc[it, "seed"] = seed

        all_cfgs[ansatz][qubits][seed][noise][str(noise_value)]["RX"][2000] += 1
        if (
            all_cfgs[ansatz][qubits][seed][noise][str(noise_value)]["RX"] > 1
            or qubits == 7
        ):
            continue

        sub_df_b = get_csv_artifact(run_id, "expressibility_noise")
        df = pd.concat(
            [df, pd.merge(sub_df_a.iloc[[-1]], sub_df_b, how="cross")]
        ).reset_index(drop=True)

    if debug:
        check_complete(all_cfgs, problem_seeds=[2000])

    return df


def get_entanglement_df(
    run_ids,
    debug=False,
):
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
            "ThermalRelaxation",
            "StatePreparation",
            "Measurement",
            "entangling_capability",
        ]
    )
    all_cfgs = init_all_cfg_dict()

    for it, run_id in track(
        enumerate(run_ids),
        description="Collecting entanglement data..",
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

        ansatz = client.get_run(run_id).data.params["model.circuit_type"]
        sub_df_a.loc[it, "ansatz"] = ansatz

        measure = client.get_run(run_id).data.params.get("entanglement.measure", "EF")
        sub_df_a.loc[it, "measure"] = measure

        qubits = int(client.get_run(run_id).data.params["model.n_qubits"])
        sub_df_a.loc[it, "qubits"] = qubits

        seed = int(client.get_run(run_id).data.params["seed"])
        sub_df_a.loc[it, "seed"] = seed

        noise_params = client.get_run(run_id).data.params["model.noise_params"]
        noise = [
            k
            for k, v in ast.literal_eval(noise_params).items()
            if not isinstance(v, dict) and float(v) > 0.0
        ]
        if len(noise) > 0:
            noise = noise[0]
        else:
            noise = "noiseless"
        noise_value = [
            v for k, v in ast.literal_eval(noise_params).items() if float(v) > 0.0
        ]
        if len(noise_value) > 0:
            noise_value = noise_value[0]
        else:
            noise_value = 0
        all_cfgs[ansatz][qubits][seed][noise][str(noise_value)]["RX"][2000] += 1

        try:
            sub_df_b = get_csv_artifact(run_id, "entangling_capability_noise")
            df = pd.concat(
                [df, pd.merge(sub_df_a.iloc[[-1]], sub_df_b, how="cross")]
            ).reset_index(drop=True)
        except:
            print(f"No entanglement for run {run_id}")
            sub_df_b = pd.DataFrame()
            all_cfgs[ansatz][qubits][seed][noise][str(noise_value)]["RX"] -= 1

    if debug:
        check_complete(all_cfgs, problem_seeds=[2000])

    return df


def get_symbol_iterator():
    raw_symbols = SymbolValidator().values
    symbols = []
    for i in range(0, len(raw_symbols), 12):
        symbols.append(raw_symbols[i])

    return iter(symbols)


def init_all_cfg_dict():
    all_cfgs = dict()
    for circuit_type in [
        "Hardware_Efficient",
        "Strongly_Entangling",
        "Strongly_Entangling_Plus",
        "Circuit_15",
        "Circuit_19",
    ]:
        all_cfgs[circuit_type] = dict()
        for n_qubits in range(1, 8):
            all_cfgs[circuit_type][n_qubits] = dict()
            for seed in list(range(1000, 1010)) + ["None"]:
                all_cfgs[circuit_type][n_qubits][seed] = dict()
                for noise in [
                    "BitFlip",
                    "PhaseFlip",
                    "AmplitudeDamping",
                    "PhaseDamping",
                    "Depolarizing",
                    "StatePreparation",
                    "Measurement",
                    "GateError",
                    "noiseless",
                ]:
                    all_cfgs[circuit_type][n_qubits][seed][noise] = dict()
                    for noise_value in ["0", "0.004", "0.03", "0.06", "0.1"]:
                        all_cfgs[circuit_type][n_qubits][seed][noise][noise_value] = (
                            dict()
                        )
                        for encoding in ["RX", "RY", "RZ", "RXRY"]:
                            all_cfgs[circuit_type][n_qubits][seed][noise][noise_value][
                                encoding
                            ] = dict()
                            for problem_seed in range(2000, 2010):
                                all_cfgs[circuit_type][n_qubits][seed][noise][
                                    noise_value
                                ][encoding][problem_seed] = 0

    return all_cfgs


def check_complete(
    all_cfgs: dict,
    export_qubits: List[int] = [2, 3, 4, 5, 6],
    export_noise_types=[
        "BitFlip",
        "PhaseFlip",
        "AmplitudeDamping",
        "PhaseDamping",
        "Depolarizing",
        "StatePreparation",
        "Measurement",
        "GateError",
        "noiseless",
    ],
    problem_seeds=[2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009],
):
    for circuit_type in [
        "Hardware_Efficient",
        "Strongly_Entangling",
        "Circuit_15",
        "Circuit_19",
    ]:
        for n_qubits in export_qubits:
            for seed in range(1000, 1005):
                for noise in export_noise_types:
                    for noise_value in ["0.03"]:
                        if noise_value == "0" and noise != "noiseless":
                            continue
                        for encoding in ["RX", "RY"]:
                            if (
                                encoding == "RX"
                                and circuit_type == "Circuit_15"
                                or encoding == "RY"
                                and circuit_type != "Circuit_15"
                            ):
                                continue
                            for problem_seed in problem_seeds:
                                if (
                                    all_cfgs[circuit_type][n_qubits][seed][noise][
                                        noise_value
                                    ][encoding][problem_seed]
                                    != 1
                                ):
                                    print(
                                        f"Got {all_cfgs[circuit_type][n_qubits][seed][noise][noise_value][encoding][problem_seed]} for "
                                        f"{circuit_type}, {n_qubits}, {seed}, {noise}={noise_value}, {encoding}, "
                                        f"ps={problem_seed}"
                                    )


def get_coeffs_df(
    run_ids,
    export_full_coeffs=False,
    skip_rx_circ15=False,
    export_qubits=[2, 3, 4, 5, 6],
    export_noise_types=[
        "BitFlip",
        "PhaseFlip",
        "AmplitudeDamping",
        "PhaseDamping",
        "Depolarizing",
        "StatePreparation",
        "Measurement",
        "GateError",
        "noiseless",
    ],
    debug=False,
):
    columns = [
        "run_id",
        "ansatz",
        "qubits",
        "seed",
        "encoding",
        "BitFlip",
        "PhaseFlip",
        "AmplitudeDamping",
        "PhaseDamping",
        "Depolarizing",
        "StatePreparation",
        "Measurement",
        "GateError",
    ]
    array_cols = [
        "coeffs_abs_var",
        "coeffs_abs_mean",
        "coeffs_real_mean",
        "coeffs_imag_mean",
        "coeffs_var",
        "coeffs_real_var",
        "coeffs_imag_var",
        "coeffs_co_var_real_imag",
        "frequencies",
    ]
    additional_cols = [
        "coeffs_abs_min",
        "coeffs_abs_max",
    ]
    big_array_cols = ["coeffs_full_real", "coeffs_full_imag"]
    columns.extend(array_cols + additional_cols)
    if export_full_coeffs:
        columns.extend(big_array_cols)
    df = pd.DataFrame(columns=columns)

    def converter(s):
        s = s.replace("\n", "")
        s = s.replace("[", "")
        s = s.replace("]", "")
        return np.fromstring(s, dtype=float, sep=" ")

    def list_converter(s):
        return np.array(ast.literal_eval(s), dtype=float)

    def do_nothing_converter(s):
        return None

    def mean_converter(s):
        values = converter(s)
        return np.mean(values)

    def var_converter(s):
        values = converter(s)
        return np.mean(values)

    print(
        "\nThis a hint that there is some very inefficient code.. :) Checkout a xkcd comic while waiting: https://c.xkcd.com/random/comic/\n"
    )

    client = mlflow.tracking.MlflowClient()

    all_cfgs = init_all_cfg_dict()

    for it, run_id in track(
        enumerate(run_ids),
        description="Collecting coefficients data..",
        total=len(run_ids),
    ):
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

        ansatz = client.get_run(run_id).data.params["model.circuit_type"]
        sub_df_a.loc[it, "ansatz"] = ansatz

        qubits = int(client.get_run(run_id).data.params["model.n_qubits"])
        sub_df_a.loc[it, "qubits"] = qubits

        if qubits not in export_qubits:
            continue

        seed = int(client.get_run(run_id).data.params["seed"])
        sub_df_a.loc[it, "seed"] = seed

        noise_params = client.get_run(run_id).data.params["model.noise_params"]
        encoding = client.get_run(run_id).data.params.get("model.encoding", "RX")
        scale = client.get_run(run_id).data.params.get("coefficients.scale", False)
        sub_df_a.loc[it, "scale"] = scale

        n_input_feat = int(
            client.get_run(run_id).data.params.get("model.n_input_feat", 1)
        )
        if n_input_feat == 2:
            encoding = "RXRY"
        n_input_feat = (
            len(ast.literal_eval(encoding)) if "[" in encoding else n_input_feat
        )
        if encoding == "['RX', 'RY']":
            encoding = "RXRY"
        sub_df_a.loc[it, "encoding"] = encoding
        sub_df_a.loc[it, "n_input_feat"] = n_input_feat

        noise = [k for k, v in ast.literal_eval(noise_params).items() if float(v) > 0.0]
        if len(noise) == 0:
            noise = "noiseless"
            noise_value = 0
        else:
            noise = noise[0]
            noise_value = [
                v for k, v in ast.literal_eval(noise_params).items() if float(v) > 0.0
            ][0]

        if noise not in export_noise_types:
            continue

        all_cfgs[ansatz][qubits][seed][noise][str(noise_value)][encoding][2000] += 1
        if (
            skip_rx_circ15
            and encoding != "RY"
            and ansatz == "Circuit_15"
            and n_input_feat == 1
        ):
            continue

        converter_dict = {c: list_converter for c in array_cols + big_array_cols}

        try:
            sub_df_b = get_csv_artifact(
                run_id,
                "coefficients_noise",
                converters=converter_dict,
            )
            sub_df_b["coeffs_abs"] = (
                sub_df_b["coeffs_full_real"] ** 2 + sub_df_b["coeffs_full_imag"] ** 2
            )
            sub_df_b["coeffs_abs"] = sub_df_b["coeffs_abs"].map(np.sqrt)
            sub_df_b["coeffs_abs_min"] = sub_df_b["coeffs_abs"].map(
                lambda x: np.min(x, axis=-1)
            )
            sub_df_b["coeffs_abs_max"] = sub_df_b["coeffs_abs"].map(
                lambda x: np.max(x, axis=-1)
            )
            sub_df_b.drop(columns=["coeffs_abs"], inplace=True)

            if not export_full_coeffs:
                sub_df_b.drop(columns=big_array_cols, inplace=True)

            df = pd.concat(
                [df, pd.merge(sub_df_a.iloc[[-1]], sub_df_b, how="cross")]
            ).reset_index(drop=True)

        except Exception:
            print(f"No coefficients for run {run_id}")
            sub_df_b = pd.DataFrame()
            all_cfgs[ansatz][qubits][seed][noise][str(noise_value)][encoding][2000] -= 1

    if debug:
        check_complete(
            all_cfgs, export_qubits, export_noise_types, problem_seeds=[2000]
        )

    return df


def expand_coeffs(df, metric):
    qubits = sorted(df.qubits.unique())
    n_qubits = max(qubits)

    for idx in df.index:
        for freq in range(df.loc[idx, metric].size):
            df.loc[idx, f"{metric}_{freq}"] = df.loc[idx, metric][freq].item()

    return df


def assign_ansatz_id(df):
    # add a column with name "ansatz_id" where each ansatz has a unique id
    df["ansatz_id"] = df["ansatz"].factorize()[0]
    return df


def run_ids_from_experiment_id(
    experiment_ids: Union[List[str], str],
    existing_run_ids: Optional[List[str]],
    experiment_type: Optional[str] = None,
    n: Optional[int] = None,
):
    filter_string = (
        f"tags.pipeline_name = '{experiment_type}'"
        if experiment_type is not None
        else None
    )
    runs = mlflow.search_runs(experiment_ids, filter_string=filter_string)

    run_ids = runs["run_id"].to_list()
    if n is not None:
        run_ids = run_ids[:n]
    runs = [r for r in run_ids if r not in existing_run_ids]

    return runs
