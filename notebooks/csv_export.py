from runs.coefficient_runs import experiment_ids as coeff_eids
from runs.expressibility_runs import experiment_ids as expr_eids
from runs.entanglement_runs import experiment_id as ent_eids
import pandas as pd
from helper import (
    get_coeffs_df,
    run_ids_from_experiment_id,
    get_expressibility_df,
    get_entanglement_df,
)

test_crun_ids = ["5729a84332b7461097dec7054f43dd60"]
coeffs_df = get_coeffs_df(test_crun_ids)

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

for ac in array_columns:
    coeffs_df[ac] = coeffs_df[ac].apply(list)

coeffs_df["original_idx"] = coeffs_df.index

df_exploded = coeffs_df.explode(array_columns, ignore_index=True)
df_exploded["test_cidx"] = df_exploded.groupby("original_idx").cumcount()
df_exploded.to_csv("notebooks/rplots/csv_data/test_coeffs.csv", index=False)
print("Exported Test Coefficient Data")

coeff_run_ids = run_ids_from_experiment_id(coeff_eids)
coeffs_df = get_coeffs_df(coeff_run_ids)
coeffs_df["coeffs_abs_var"] = coeffs_df["coeffs_abs_var"].apply(list)
coeffs_df["coeffs_abs_mean"] = coeffs_df["coeffs_abs_mean"].apply(list)
coeffs_df["original_idx"] = coeffs_df.index

coeffs_df["frequency"] = coeffs_df["frequencies"].apply(list)
coeffs_df["original_idx"] = coeffs_df.index

df_exploded = coeffs_df.explode(
    ["coeffs_abs_var", "coeffs_abs_mean", "frequency"], ignore_index=True
)
df_exploded["coeff_idx"] = df_exploded.groupby("original_idx").cumcount()
df_exploded.to_csv("notebooks/rplots/csv_data/coeffs.csv", index=False)
print("Exported Coefficient Data")

expr_run_ids = run_ids_from_experiment_id(expr_eids)
expr_df = get_expressibility_df(expr_run_ids)
expr_df.to_csv("notebooks/rplots/csv_data/expr.csv", index=False)
print("Exported Expressibility Data")

ent_run_ids = run_ids_from_experiment_id(ent_eids)
ent_df = get_entanglement_df(ent_run_ids)
ent_df.to_csv("notebooks/rplots/csv_data/entanglement.csv", index=False)
print("Exported Entanglement Data")
