import plotly.graph_objects as go
import plotly.io as pio
from runs.expressibility_ansatz_runs import run_ids, experiment_id
from helper import (
    save_fig,
    get_expressibility_df,
    rgb_to_rgba,
    get_qual_color_iterator,
    assign_ansatz_id,
)

pio.kaleido.scope.mathjax = None

expr_df = get_expressibility_df(run_ids)
expr_df.sort_values(by="ansatz", inplace=True)
expr_df = assign_ansatz_id(expr_df)

ansaetze = expr_df.ansatz.unique()

main_colors_it, sec_colors_it = get_qual_color_iterator()

fig = go.Figure()
for ansatz in ansaetze:
    main_color_sel = next(main_colors_it)
    sec_color_sel = rgb_to_rgba(next(sec_colors_it), 0.2)

    metric_values = (
        expr_df[expr_df.ansatz == ansatz]
        .groupby("noise_level")
        .expressibility.agg(["mean", "min", "max"])
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

fig.update_layout(
    title=f"KL Divergence Mean for Different Ansaetze over Noise Level",
    template="plotly_white",
    yaxis=dict(title="KL Divergence Mean"),
    xaxis=dict(title="Noise Level"),
)

save_fig(fig, "expr_noise_level", run_ids, experiment_id)
