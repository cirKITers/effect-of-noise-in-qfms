import plotly.graph_objects as go
import plotly.io as pio
from runs.coefficient_runs import run_ids, experiment_id
from helper import (
    save_fig,
    get_coeffs_df,
    rgb_to_rgba,
    get_color_iterator,
    assign_ansatz_id,
)

pio.kaleido.scope.mathjax = None

coeffs_df = get_coeffs_df(run_ids)
coeffs_df.sort_values(by="qubits", inplace=True)
coeffs_df = assign_ansatz_id(coeffs_df)

ansaetze = coeffs_df.ansatz.unique()


for metric in ["coeffs_abs_var", "coeffs_abs_mean"]:
    fig = go.Figure()
    main_colors_it, sec_colors_it = get_color_iterator()
    for ansatz in ansaetze:
        main_color_sel = next(main_colors_it)
        sec_color_sel = rgb_to_rgba(next(sec_colors_it), 0.2)

        metric_values = (
            coeffs_df[coeffs_df.ansatz == ansatz]
            .groupby("noise_level")[metric]
            .agg(["mean", "min", "max"])
        )

        fig.add_trace(
            go.Scatter(
                x=metric_values.index,
                y=metric_values["mean"],
                name=ansatz,
                mode="lines",
                line=dict(color=main_color_sel),
                marker=dict(color=main_color_sel),
            )
        )
        fig.add_trace(
            go.Scatter(
                x=metric_values.index,
                y=metric_values["max"],
                name=f"upper-{ansatz}",
                visible=True,
                mode="lines",
                line=dict(width=0),
                showlegend=False,
            )
        )
        fig.add_trace(
            go.Scatter(
                x=metric_values.index,
                y=metric_values["min"],
                name=f"lower-{ansatz}",
                visible=True,
                mode="lines",
                fill="tonexty",
                fillcolor=sec_color_sel,
                marker=dict(color=main_color_sel),
                line=dict(width=0),
                showlegend=False,
            )
        )

    title = metric.replace("_", " ").title()
    fig.update_layout(
        title=f"{title} for Different Ansaetze over Noise Level",
        template="plotly_white",
        yaxis=dict(title="Coefficients Mean"),
        xaxis=dict(title="Noise Level"),
    )

    save_fig(fig, f"{metric}_noise_level", run_ids, experiment_id)
