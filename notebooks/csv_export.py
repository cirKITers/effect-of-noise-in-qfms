import pandas as pd
import os
import argparse
from helper import (
    get_coeffs_df,
    run_ids_from_experiment_id,
    get_expressibility_df,
    get_entanglement_df,
)
from typing import Optional
from runs.coefficient_runs import experiment_ids as coeff_eids
from runs.coefficient_runs import experiment_ids_encoding as coeff_enc_eids
from runs.expressibility_runs import experiment_ids as expr_eids
from runs.entanglement_runs import experiment_ids as ent_eids

CSV_DESTINATION = "plotting/rplots/csv_data"

id_ent_file = f"{CSV_DESTINATION}/ent_ids.csv"
id_expr_file = f"{CSV_DESTINATION}/expr_ids.csv"


def export_encoding_coeff_data(
    export_full=True,
    export_qubits=[2, 3, 4, 5, 6],
):
    id_coeff_file = (
        f"{CSV_DESTINATION}/coeffs_encoding_ids.csv"
        if export_full
        else f"{CSV_DESTINATION}/coeffs_encoding_ids_small.csv"
    )
    if os.path.exists(id_coeff_file):
        id_coeffs = pd.read_csv(id_coeff_file)
    else:
        id_coeffs = pd.DataFrame(columns=["run_id"])

    coeff_run_ids = run_ids_from_experiment_id(
        coeff_enc_eids, existing_run_ids=id_coeffs["run_id"].to_list()
    )
    if len(coeff_run_ids) == 0:
        return
    all_coeffs_df = get_coeffs_df(
        coeff_run_ids,
        export_full_coeffs=export_full,
        export_qubits=export_qubits,
        export_noise_types=["noiseless"],
    )

    array_columns = [
        "coeffs_abs_mean",
        "coeffs_real_mean",
        "coeffs_imag_mean",
        "coeffs_abs_var",
        "coeffs_var",
        "coeffs_real_var",
        "coeffs_imag_var",
        "coeffs_co_var_real_imag",
        "frequencies",
    ]

    big_array_columns = [
        "coeffs_full_real",
        "coeffs_full_imag",
    ]

    for n_dims in range(1, 3):
        coeffs_df = all_coeffs_df[all_coeffs_df["n_input_feat"] == n_dims]
        if coeffs_df.size == 0:
            continue

        for d in range(n_dims):
            cols = array_columns + big_array_columns if export_full else array_columns
            for ac in cols:
                coeffs_df[ac] = coeffs_df[ac].apply(list)

            coeffs_df["original_idx"] = coeffs_df.index
            coeffs_df = coeffs_df.explode(cols, ignore_index=True)
            coeffs_df[f"coeff{d}_idx"] = coeffs_df.groupby("original_idx").cumcount()

        coeffs_df[[f"freq{d + 1}" for d in range(n_dims)]] = pd.DataFrame(
            coeffs_df["frequencies"].to_list(), index=coeffs_df.index
        )
        coeffs_df = coeffs_df.drop(columns=["frequencies"])

        if export_full:
            for ac in big_array_columns:
                coeffs_df[ac] = coeffs_df[ac].apply(list)

            coeffs_df["original_coeff_idx"] = coeffs_df.index
            coeffs_df_full = coeffs_df.explode(big_array_columns, ignore_index=True)
            coeffs_df_full["sample_idx"] = coeffs_df_full.groupby(
                "original_coeff_idx"
            ).cumcount()

            result_file = f"{CSV_DESTINATION}/coeffs_enc_full_dims{n_dims}.csv"
            if os.path.exists(result_file):
                coeffs_df_full.to_csv(result_file, index=False, mode="a", header=False)
            else:
                coeffs_df_full.to_csv(result_file, index=False)
            print(f"Exported Full Coefficient Data for {n_dims} dims")
        else:
            coeffs_df = coeffs_df.drop(columns=big_array_columns)
            result_file = f"{CSV_DESTINATION}/coeffs_enc_stat_dims{n_dims}.csv"
            if os.path.exists(result_file):
                coeffs_df.to_csv(result_file, index=False, mode="a", header=False)
            else:
                coeffs_df.to_csv(result_file, index=False)
            print(f"Exported Stat Coefficient Data for {n_dims} dims")

    additional_runs = pd.DataFrame(all_coeffs_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_coeffs, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_coeff_file, index=False)
    print("Exported Indices")


def export_coeff_data(
    export_full=True,
    export_qubits=[2, 3, 4, 5, 6],
    export_noise_types=[
        "AmplitudeDamping",
        "PhaseDamping",
        "Depolarizing",
        "BitFlip",
        "PhaseFlip",
        "GateError",
        "Measurement",
        "StatePreparation",
        "noiseless",
    ],
    experiment_id: Optional[str] = None,
    single: bool = False,
):
    global CSV_DESTINATION
    if single:
        dest = f"{CSV_DESTINATION}/single"
    else:
        dest = CSV_DESTINATION
    os.makedirs(dest, exist_ok=True)
    id_coeff_file = (
        f"{dest}/coeffs_ids.csv"
        if export_full
        else f"{CSV_DESTINATION}/coeffs_ids_small.csv"
    )
    if os.path.exists(id_coeff_file):
        id_coeffs = pd.read_csv(id_coeff_file)
    else:
        id_coeffs = pd.DataFrame(columns=["run_id"])

    eids = coeff_eids if experiment_id is None else [experiment_id]
    coeff_run_ids = run_ids_from_experiment_id(
        eids,
        existing_run_ids=id_coeffs["run_id"].to_list(),
        experiment_type="coefficients",
    )
    if len(coeff_run_ids) == 0:
        return
    all_coeffs_df = get_coeffs_df(
        coeff_run_ids,
        export_full_coeffs=export_full,
        skip_rx_circ15=not single,
        export_qubits=export_qubits,
        export_noise_types=export_noise_types,
    )
    if all_coeffs_df.size == 0:
        return

    array_columns = [
        "coeffs_abs_mean",
        "coeffs_real_mean",
        "coeffs_imag_mean",
        "coeffs_abs_var",
        "coeffs_var",
        "coeffs_real_var",
        "coeffs_imag_var",
        "coeffs_co_var_real_imag",
        "frequencies",
    ]

    big_array_columns = [
        "coeffs_full_real",
        "coeffs_full_imag",
    ]
    cols = array_columns + big_array_columns if export_full else array_columns

    for n_dims in range(1, 3):
        coeffs_df = all_coeffs_df[all_coeffs_df["n_input_feat"] == n_dims]
        if coeffs_df.size == 0:
            continue

        if n_dims == 2:
            for ac in cols:
                coeffs_df = coeffs_df.drop(
                    coeffs_df[coeffs_df[ac].map(lambda x: len(x.shape)) == 0].index
                )
                coeffs_df.reset_index()

        for d in range(n_dims):
            coeffs_df["original_idx"] = coeffs_df.index

            for ac in cols:
                coeffs_df[ac] = coeffs_df[ac].apply(list)

            coeffs_df = coeffs_df.explode(cols, ignore_index=True)
            coeffs_df[f"coeff{d}_idx"] = coeffs_df.groupby("original_idx").cumcount()

        coeffs_df[[f"freq{d + 1}" for d in range(n_dims)]] = pd.DataFrame(
            coeffs_df["frequencies"].to_list(), index=coeffs_df.index
        )
        coeffs_df = coeffs_df.drop(columns=["frequencies"])

        if export_full:
            for ac in big_array_columns:
                coeffs_df[ac] = coeffs_df[ac].apply(list)

            coeffs_df["original_coeff_idx"] = coeffs_df.index
            coeffs_df_full = coeffs_df.explode(big_array_columns, ignore_index=True)
            coeffs_df_full["sample_idx"] = coeffs_df_full.groupby(
                "original_coeff_idx"
            ).cumcount()

            for q in export_qubits:
                for noise_type in export_noise_types:
                    coeffs_selected = coeffs_df_full[
                        (coeffs_df_full[noise_type] > 0)
                        & (coeffs_df_full["qubits"] == q)
                    ]
                    result_file = (
                        f"{dest}/coeffs_full_dims{n_dims}_q{q}_{noise_type}.csv"
                    )
                    if os.path.exists(result_file):
                        coeffs_selected.to_csv(
                            result_file, index=False, mode="a", header=False
                        )
                    else:
                        coeffs_selected.to_csv(result_file, index=False)
                    print(
                        f"Exported Full Coefficient Data for {n_dims} dims, {noise_type} and {q} qubits"
                    )
        else:
            coeffs_df = coeffs_df.drop(columns=big_array_columns)
            if single:
                result_file = f"{dest}/coeffs_stat.csv"
            else:
                result_file = f"{dest}/coeffs_stat_dims{n_dims}.csv"
            if os.path.exists(result_file) and not single:
                coeffs_df.to_csv(result_file, index=False, mode="a", header=False)
            else:
                coeffs_df.to_csv(result_file, index=False)
            print(
                f"Exported Stat Coefficient Data for {n_dims} dims, {export_noise_types} and {export_qubits} qubits"
            )

    additional_runs = pd.DataFrame(all_coeffs_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_coeffs, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_coeff_file, index=False)
    print("Exported Indices")


def export_expr_data(
    experiment_id: Optional[str] = None,
    single: bool = False,
):
    global CSV_DESTINATION
    if single:
        dest = f"{CSV_DESTINATION}/single"
    else:
        dest = CSV_DESTINATION
    os.makedirs(dest, exist_ok=True)
    if os.path.exists(id_expr_file):
        id_expr = pd.read_csv(id_expr_file)
    else:
        id_expr = pd.DataFrame(columns=["run_id"])
    eids = expr_eids if experiment_id is None else [experiment_id]
    expr_run_ids = run_ids_from_experiment_id(
        eids,
        existing_run_ids=id_expr["run_id"].to_list(),
        experiment_type="expressibility",
    )
    if len(expr_run_ids) == 0:
        return
    expr_df = get_expressibility_df(expr_run_ids)
    result_file = f"{dest}/expr.csv"
    if os.path.exists(result_file) and not single:
        expr_df.to_csv(result_file, index=False, mode="a", header=False)
    else:
        expr_df.to_csv(result_file, index=False)
    print("Exported Expressibility Data")

    additional_runs = pd.DataFrame(expr_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_expr, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_expr_file, index=False)
    print("Exported Indices")


def export_ent_data(
    experiment_id: Optional[str] = None,
    single: bool = False,
):
    global CSV_DESTINATION
    if single:
        dest = f"{CSV_DESTINATION}/single"
    else:
        dest = CSV_DESTINATION
    os.makedirs(dest, exist_ok=True)
    if os.path.exists(id_ent_file):
        id_ent = pd.read_csv(id_ent_file)
    else:
        id_ent = pd.DataFrame(columns=["run_id"])
    eid = ent_eids if experiment_id is None else [experiment_id]
    ent_run_ids = run_ids_from_experiment_id(
        eid, existing_run_ids=id_ent["run_id"].to_list(), experiment_type="entanglement"
    )
    if len(ent_run_ids) == 0:
        return
    ent_df = get_entanglement_df(ent_run_ids)
    result_file = f"{dest}/ent.csv"
    if os.path.exists(result_file) and not single:
        ent_df.to_csv(result_file, index=False, mode="a", header=False)
    else:
        ent_df.to_csv(result_file, index=False)
    print("Exported Entanglement Data")

    additional_runs = pd.DataFrame(ent_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_ent, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_ent_file, index=False)
    print("Exported Indices")


def get_arg_parser():
    parser = argparse.ArgumentParser(
        prog="MLFlow -> CSV Exporter",
        description="Collect result data from Kedro/MLFlow runs and create summarised CSV files for plotting.",
    )
    parser.add_argument(
        "-n", "--n_qubits", default="all", help='"all" or one of [3|4|5|6]'
    )
    parser.add_argument(
        "-nt",
        "--noise_type",
        default="all",
        help='"all" or one of [BitFlip|PhaseFlip|Depolarizing|AmplitudeDamping|PhaseDamping|StatePreparation|Measurement|GateError]',
    )
    parser.add_argument(
        "-s",
        "--single",
        default=False,
        action="store_true",
        help="Whether to export single run",
    )
    parser.add_argument(
        "-eid",
        "--experiment_id",
        help="Experiment ID",
    )
    parser.add_argument(
        "-coeff",
        "--coefficients",
        action="store_true",
        default=False,
        help="Store coefficient data",
    )
    parser.add_argument(
        "-fullcoeff",
        "--full_coefficients",
        action="store_true",
        default=False,
        help="Store full coefficient data",
    )
    parser.add_argument(
        "-enccoeff",
        "--encoding_coefficients",
        action="store_true",
        default=False,
        help="Store full coefficient data",
    )
    parser.add_argument(
        "-expr",
        "--expressibility",
        action="store_true",
        default=False,
        help="Store expressibility data",
    )
    parser.add_argument(
        "-ent",
        "--entanglement",
        action="store_true",
        default=False,
        help="Store entangling capability data",
    )
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    p = get_arg_parser()
    kwargs = dict()
    if p.n_qubits != "all":
        kwargs["export_qubits"] = [int(p.n_qubits)]

    if p.noise_type != "all":
        kwargs["export_noise_types"] = [p.noise_type]

    if p.coefficients:
        export_coeff_data(
            False,
            experiment_id=p.experiment_id,
            single=p.single,
            **kwargs,
        )
    if p.full_coefficients:
        export_coeff_data(
            True,
            experiment_id=p.experiment_id,
            **kwargs,
        )
    if p.encoding_coefficients:
        export_encoding_coeff_data(
            True,
            **kwargs,
        )
    if p.expressibility:
        export_expr_data(experiment_id=p.experiment_id, single=p.single)
    if p.entanglement:
        export_ent_data(experiment_id=p.experiment_id, single=p.single)
