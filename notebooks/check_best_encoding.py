import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.io as pio
from runs.encoding_runs import run_ids, experiment_id
from qml_essentials.coefficients import Coefficients
from helper import (
    save_fig,
    get_coeffs_df,
    rgb_to_rgba,
    get_seq_color_iterator,
    assign_ansatz_id,
    expand_coeffs,
    get_symbol_iterator,
)
import numpy as np

pio.kaleido.scope.mathjax = None

coeffs_df = get_coeffs_df(run_ids, export_full_coeffs=True)
coeffs_df.sort_values(by="ansatz", inplace=True)
coeffs_df = assign_ansatz_id(coeffs_df)
# coeffs_df = expand_coeffs(coeffs_df, "coeffs_abs_mean")

ansaetze = coeffs_df.ansatz.unique()
qubits = sorted(coeffs_df.qubits.unique())
encodings = sorted(coeffs_df.encoding.unique())

for ansatz in ansaetze:
    fig = make_subplots(specs=[[{"secondary_y": True}]])
    main_colors_it = get_seq_color_iterator(len(qubits))
    for qubit in qubits:
        main_color_sel = next(main_colors_it)
        symbols = get_symbol_iterator()
        for encoding in encodings:
            symbol = next(symbols)

            # def has_n_frequencies(v):
            #     if v.size == qubit + 1:
            #         return True
            #     return False

            # valid = coeffs_df[
            #     (coeffs_df.ansatz == ansatz)
            #     & (coeffs_df.qubits == qubit)
            #     & (coeffs_df.encoding == encoding)
            # ]["frequencies"].agg([has_n_frequencies])

            # if not valid:
            #     continue

            try:

                def array_mean(v):
                    return np.stack(v.array).mean(axis=0)

                def array_max(v):
                    return np.stack(v.array).mean(axis=0)

                coeff_mean_metric_values = coeffs_df[
                    (coeffs_df.ansatz == ansatz)
                    & (coeffs_df.qubits == qubit)
                    & (coeffs_df.encoding == encoding)
                ]["coeffs_abs_mean"].agg([array_mean, array_max])

                fig.add_trace(
                    go.Scatter(
                        y=coeff_mean_metric_values["array_mean"],
                        name=f"{qubit} Qubits - {encoding} Mean",
                        mode="lines+markers",
                        line=dict(color=main_color_sel),
                        marker=dict(color=main_color_sel, symbol=symbol),
                    )
                )
            except Exception as e:
                print(e)
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

fig.update_yaxes(title_text=f"Magnitude", secondary_y=False)
fig.update_xaxes(title_text="Frequency")
fig.update_layout(
    title=f"Spectrogram",
    template="plotly_white",
    yaxis_type="log",
    # legend=dict(x=1.2),
    width=1200,
)
save_fig(
    fig,
    f"{ansatz.lower()}_level",
    run_ids,
    experiment_id,
)
fig.show()
