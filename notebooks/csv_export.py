from runs.coefficient_runs import experiment_ids as coeff_eids
from runs.expressibility_runs import experiment_ids as expr_eids
from runs.entanglement_runs import experiment_ids as ent_eids
import pandas as pd
from helper import (
    get_coeffs_df,
    run_ids_from_experiment_id,
    get_expressibility_df,
    get_entanglement_df,
)

coeff_run_ids = run_ids_from_experiment_id(coeff_eids)
all_coeffs_df = get_coeffs_df(coeff_run_ids, export_full_coeffs=True)

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
        for ac in array_columns + big_array_columns:
            coeffs_df[ac] = coeffs_df[ac].apply(list)

        coeffs_df["original_idx"] = coeffs_df.index
        coeffs_df = coeffs_df.explode(
            array_columns + big_array_columns, ignore_index=True
        )
        coeffs_df[f"coeff{d}_idx"] = coeffs_df.groupby("original_idx").cumcount()

    coeffs_df[[f"freq{d+1}" for d in range(n_dims)]] = pd.DataFrame(
        coeffs_df["frequencies"].to_list(), index=coeffs_df.index
    )
    coeffs_df = coeffs_df.drop(columns=["frequencies"])

    for ac in big_array_columns:
        coeffs_df[ac] = coeffs_df[ac].apply(list)

    coeffs_df["original_coeff_idx"] = coeffs_df.index
    coeffs_df_full = coeffs_df.explode(big_array_columns, ignore_index=True)
    coeffs_df_full["sample_idx"] = coeffs_df_full.groupby(
        "original_coeff_idx"
    ).cumcount()

    coeffs_df_full.to_csv(
        f"notebooks/rplots/csv_data/coeffs_full_dims{n_dims}.csv", index=False
    )
    print(f"Exported Full Coefficient Data for {n_dims} dims")

expr_run_ids = run_ids_from_experiment_id(expr_eids)
expr_df = get_expressibility_df(expr_run_ids)
expr_df.to_csv("notebooks/rplots/csv_data/expr.csv", index=False)
print("Exported Expressibility Data")

ent_run_ids = run_ids_from_experiment_id(ent_eids)
ent_df = get_entanglement_df(ent_run_ids)
ent_df.to_csv("notebooks/rplots/csv_data/entanglement.csv", index=False)
print("Exported Entanglement Data")
