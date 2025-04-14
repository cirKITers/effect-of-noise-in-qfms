from runs.coefficient_runs import experiment_ids as coeff_eids
from runs.coefficient_runs import experiment_ids_encoding as coeff_enc_eids
from runs.expressibility_runs import experiment_ids as expr_eids
from runs.entanglement_runs import experiment_ids as ent_eids
import pandas as pd
import numpy as np
import os
from helper import (
    get_coeffs_df,
    run_ids_from_experiment_id,
    get_expressibility_df,
    get_entanglement_df,
)

id_ent_file = "notebooks/rplots/csv_data/ent_ids.csv"
id_expr_file = "notebooks/rplots/csv_data/expr_ids.csv"


def export_encoding_coeff_data(export_full=True):

    id_coeff_file = (
        "notebooks/rplots/csv_data/coeffs_encoding_ids.csv"
        if export_full
        else "notebooks/rplots/csv_data/coeffs_encoding_ids_small.csv"
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
    all_coeffs_df = get_coeffs_df(coeff_run_ids, export_full_coeffs=export_full)

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

        coeffs_df[[f"freq{d+1}" for d in range(n_dims)]] = pd.DataFrame(
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

            result_file = f"notebooks/rplots/csv_data/coeffs_enc_full_dims{n_dims}.csv"
            if os.path.exists(result_file):
                coeffs_df_full.to_csv(result_file, index=False, mode="a", header=False)
            else:
                coeffs_df_full.to_csv(result_file, index=False)
            print(f"Exported Full Coefficient Data for {n_dims} dims")
        else:
            coeffs_df = coeffs_df.drop(columns=big_array_columns)
            result_file = f"notebooks/rplots/csv_data/coeffs_enc_stat_dims{n_dims}.csv"
            if os.path.exists(result_file):
                coeffs_df.to_csv(result_file, index=False, mode="a", header=False)
            else:
                coeffs_df.to_csv(result_file, index=False)
            print(f"Exported Stat Coefficient Data for {n_dims} dims")

    additional_runs = pd.DataFrame(all_coeffs_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_coeffs, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_coeff_file, index=False)
    print("Exported Indices")


def export_coeff_data(export_full=True):

    id_coeff_file = (
        "notebooks/rplots/csv_data/coeffs_ids.csv"
        if export_full
        else "notebooks/rplots/csv_data/coeffs_ids_small.csv"
    )
    if os.path.exists(id_coeff_file):
        id_coeffs = pd.read_csv(id_coeff_file)
    else:
        id_coeffs = pd.DataFrame(columns=["run_id"])

    coeff_run_ids = run_ids_from_experiment_id(
        coeff_eids, existing_run_ids=id_coeffs["run_id"].to_list()
    )
    if len(coeff_run_ids) == 0:
        return
    all_coeffs_df = get_coeffs_df(
        coeff_run_ids, export_full_coeffs=export_full, skip_ry_circ15=True
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

        coeffs_df[[f"freq{d+1}" for d in range(n_dims)]] = pd.DataFrame(
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

            result_file = f"notebooks/rplots/csv_data/coeffs_full_dims{n_dims}.csv"
            if os.path.exists(result_file):
                coeffs_df_full.to_csv(result_file, index=False, mode="a", header=False)
            else:
                coeffs_df_full.to_csv(result_file, index=False)
            print(f"Exported Full Coefficient Data for {n_dims} dims")
        else:
            coeffs_df = coeffs_df.drop(columns=big_array_columns)
            result_file = f"notebooks/rplots/csv_data/coeffs_stat_dims{n_dims}.csv"
            if os.path.exists(result_file):
                coeffs_df.to_csv(result_file, index=False, mode="a", header=False)
            else:
                coeffs_df.to_csv(result_file, index=False)
            print(f"Exported Stat Coefficient Data for {n_dims} dims")

    additional_runs = pd.DataFrame(all_coeffs_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_coeffs, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_coeff_file, index=False)
    print("Exported Indices")


def export_expr_data():
    if os.path.exists(id_expr_file):
        id_expr = pd.read_csv(id_expr_file)
    else:
        id_expr = pd.DataFrame(columns=["run_id"])
    expr_run_ids = run_ids_from_experiment_id(
        expr_eids, existing_run_ids=id_expr["run_id"].to_list()
    )
    if len(expr_run_ids) == 0:
        return
    expr_df = get_expressibility_df(expr_run_ids)
    result_file = f"notebooks/rplots/csv_data/expr.csv"
    if os.path.exists(result_file):
        expr_df.to_csv(result_file, index=False, mode="a", header=False)
    else:
        expr_df.to_csv(result_file, index=False)
    print("Exported Expressibility Data")

    additional_runs = pd.DataFrame(expr_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_expr, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_expr_file, index=False)
    print("Exported Indices")


def export_ent_data():
    if os.path.exists(id_ent_file):
        id_ent = pd.read_csv(id_ent_file)
    else:
        id_ent = pd.DataFrame(columns=["run_id"])
    ent_run_ids = run_ids_from_experiment_id(
        ent_eids, existing_run_ids=id_ent["run_id"].to_list()
    )
    if len(ent_run_ids) == 0:
        return
    ent_df = get_entanglement_df(ent_run_ids)
    result_file = f"notebooks/rplots/csv_data/ent.csv"
    if os.path.exists(result_file):
        ent_df.to_csv(result_file, index=False, mode="a", header=False)
    else:
        ent_df.to_csv(result_file, index=False)
    print("Exported Entanglement Data")

    additional_runs = pd.DataFrame(ent_df["run_id"], columns=["run_id"])
    run_df = pd.concat([id_ent, additional_runs], ignore_index=True)
    run_df.drop_duplicates().to_csv(id_ent_file, index=False)
    print("Exported Indices")


if __name__ == "__main__":
    # export_coeff_data(False)
    export_encoding_coeff_data()
    # export_expr_data()
