import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.io as pio
from runs.coefficient_runs import run_ids, experiment_id
from helper import (
    save_fig,
    get_coeffs_df,
    rgb_to_rgba,
    get_color_iterator,
    assign_ansatz_id,
    expand_coeffs,
)
import pandas as pd
import numpy as np

pio.kaleido.scope.mathjax = None

coeffs_df = get_coeffs_df(run_ids)
coeffs_df.sort_values(by="ansatz", inplace=True)
coeffs_df = assign_ansatz_id(coeffs_df)
coeffs_df = expand_coeffs(coeffs_df, "coeffs_abs_mean")
coeffs_df = expand_coeffs(coeffs_df, "coeffs_abs_var")

ansaetze = coeffs_df.ansatz.unique()
qubits = sorted(coeffs_df.qubits.unique())

for ansatz in ansaetze:
    fig = make_subplots(specs=[[{"secondary_y": True}]])
    for qubit in qubits:
        main_colors_it, sec_colors_it = get_color_iterator()
        for noise in [
            "BitFlip",
            "PhaseFlip",
            "AmplitudeDamping",
            "PhaseDamping",
            "Depolarizing",
        ]:
            main_color_sel = next(main_colors_it)
            sec_color_sel = rgb_to_rgba(next(sec_colors_it), 0.2)

            coeff_mean_metric_values = (
                coeffs_df[(coeffs_df.ansatz == ansatz) & (coeffs_df.qubits == qubit)]
                .groupby(noise)[f"coeffs_abs_mean_{qubit}"]
                .agg(["mean", "min", "max"])
            )

            coeff_var_metric_values = (
                coeffs_df[(coeffs_df.ansatz == ansatz) & (coeffs_df.qubits == qubit)]
                .groupby(noise)[f"coeffs_abs_var_{qubit}"]
                .agg(["mean", "min", "max"])
            )

            fig.add_trace(
                go.Scatter(
                    x=coeff_mean_metric_values.index,
                    y=coeff_mean_metric_values["mean"],
                    name=f"{noise} Mean",
                    mode="lines",
                    line=dict(color=main_color_sel),
                    marker=dict(color=main_color_sel),
                )
            )
            fig.add_trace(
                go.Scatter(
                    x=coeff_mean_metric_values.index,
                    y=coeff_mean_metric_values["max"],
                    name=f"upper-{noise}",
                    visible=True,
                    mode="lines",
                    line=dict(width=0),
                    showlegend=False,
                )
            )
            fig.add_trace(
                go.Scatter(
                    x=coeff_mean_metric_values.index,
                    y=coeff_mean_metric_values["min"],
                    name=f"lower-{noise}",
                    visible=True,
                    mode="lines",
                    fill="tonexty",
                    fillcolor=sec_color_sel,
                    marker=dict(color=main_color_sel),
                    line=dict(width=0),
                    showlegend=False,
                )
            )

            fig.add_trace(
                go.Scatter(
                    x=coeff_var_metric_values.index,
                    y=coeff_var_metric_values["mean"],
                    name=f"{noise} Var.",
                    mode="lines",
                    line=dict(
                        color=main_color_sel,
                        dash="dot",
                    ),
                    marker=dict(color=main_color_sel),
                ),
                secondary_y=True,
            )
            fig.add_trace(
                go.Scatter(
                    x=coeff_var_metric_values.index,
                    y=coeff_var_metric_values["max"],
                    name=f"upper-{noise}",
                    visible=True,
                    mode="lines",
                    line=dict(width=0),
                    showlegend=False,
                ),
                secondary_y=True,
            )
            fig.add_trace(
                go.Scatter(
                    x=coeff_var_metric_values.index,
                    y=coeff_var_metric_values["min"],
                    name=f"lower-{noise}",
                    visible=True,
                    mode="lines",
                    fill="tonexty",
                    fillcolor=sec_color_sel,
                    marker=dict(color=main_color_sel),
                    line=dict(width=0),
                    showlegend=False,
                ),
                secondary_y=True,
            )

        fig.update_yaxes(title_text="Coefficient Mean", secondary_y=False)
        fig.update_yaxes(title_text="Coefficient Variance", secondary_y=True)
        fig.update_xaxes(title_text="Noise Level")
        fig.update_layout(
            title=f"{ansatz} - {qubit} Qubits - Coefficient Mean and Variance over Noise Level",
            template="plotly_white",
            legend=dict(x=1.2),
            width=900,
        )
        save_fig(
            fig, f"coeff_mean_var_{ansatz}_{qubit}_noise_level", run_ids, experiment_id
        )
