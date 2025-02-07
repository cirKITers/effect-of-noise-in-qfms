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
    get_symbol_iterator,
)

pio.kaleido.scope.mathjax = None

coeffs_df = get_coeffs_df(run_ids)
coeffs_df.sort_values(by="ansatz", inplace=True)
coeffs_df = assign_ansatz_id(coeffs_df)
coeffs_df = expand_coeffs(coeffs_df, "coeffs_abs_mean")
coeffs_df = expand_coeffs(coeffs_df, "coeffs_abs_var")

ansaetze = coeffs_df.ansatz.unique()
qubits = sorted(coeffs_df.qubits.unique())

for ansatz in ansaetze:
    for metric in ["coeffs_abs_mean", "coeffs_abs_var"]:
        fig = make_subplots(specs=[[{"secondary_y": True}]])
        symbols = get_symbol_iterator()
        for qubit in qubits:
            main_colors_it, sec_colors_it = get_color_iterator()
            symbol = next(symbols)
            for noise in [
                "BitFlip",
                "PhaseFlip",
                "AmplitudeDamping",
                "PhaseDamping",
                # "Depolarizing",
            ]:
                main_color_sel = next(main_colors_it)
                sec_color_sel = rgb_to_rgba(next(sec_colors_it), 0.2)

                coeff_mean_metric_values = (
                    coeffs_df[
                        (coeffs_df.ansatz == ansatz) & (coeffs_df.qubits == qubit)
                    ]
                    .groupby(noise)[f"{metric}_{qubit}"]
                    .agg(["mean", "min", "max"])
                )

                fig.add_trace(
                    go.Scatter(
                        x=coeff_mean_metric_values.index,
                        y=coeff_mean_metric_values["mean"],
                        name=f"{qubit} Qubits - {noise} Mean",
                        mode="lines+markers",
                        line=dict(color=main_color_sel),
                        marker=dict(color=main_color_sel, symbol=symbol),
                    )
                )
                # fig.add_trace(
                #     go.Scatter(
                #         x=coeff_mean_metric_values.index,
                #         y=coeff_mean_metric_values["max"],
                #         name=f"upper-{noise}",
                #         visible=True,
                #         mode="lines",
                #         line=dict(width=0),
                #         showlegend=False,
                #     )
                # )
                # fig.add_trace(
                #     go.Scatter(
                #         x=coeff_mean_metric_values.index,
                #         y=coeff_mean_metric_values["min"],
                #         name=f"lower-{noise}",
                #         visible=True,
                #         mode="lines",
                #         fill="tonexty",
                #         fillcolor=sec_color_sel,
                #         marker=dict(color=main_color_sel),
                #         line=dict(width=0),
                #         showlegend=False,
                #     )
                # )

        fig.update_yaxes(title_text=f"{metric.title()}", secondary_y=False)
        fig.update_xaxes(title_text="Noise Level")
        fig.update_layout(
            title=f"{ansatz.title()} - {metric.title()} over Noise Level",
            template="plotly_white",
            yaxis_type="log",
            legend=dict(x=1.2),
            width=900,
        )
        save_fig(
            fig,
            f"{metric}_{ansatz.lower()}_{qubit}_noise_level",
            run_ids,
            experiment_id,
        )
