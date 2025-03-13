import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.io as pio
from runs.coefficient_runs import run_ids, experiment_id
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

pio.kaleido.scope.mathjax = None

experiment_id = "939685904901998130"
run_ids = [
    "90b725e91197435c8c6c69fffb22c2a5"
]  # ["81bddb7a81c245b8bac4c5afaadf00f0"]  #   b4d0a4dd9ba243ba8569809ffc4676b9

coeffs_df = get_coeffs_df(run_ids)
coeffs_df.sort_values(by="ansatz", inplace=True)
coeffs_df = assign_ansatz_id(coeffs_df)
# coeffs_df = expand_coeffs(coeffs_df, "coeffs_abs_mean")

ansaetze = coeffs_df.ansatz.unique()
qubits = sorted(coeffs_df.qubits.unique())
noise_levels = sorted(coeffs_df.noise_level.unique())

enabled_noise = [
    "GateError",
    # "BitFlip",
    # "PhaseFlip",
    # "AmplitudeDamping",
    # "PhaseDamping",
    # "Depolarizing",
]

for ansatz in ansaetze:
    fig = make_subplots(specs=[[{"secondary_y": True}]])
    for qubit in qubits:
        n_samples = len(coeffs_df[coeffs_df.qubits == qubit].coeffs_abs_mean[0])

        main_colors_it = get_seq_color_iterator(len(noise_levels))

        last_coeffs = None
        for n_it, noise_level in enumerate(noise_levels):
            if n_it != 0:
                continue
            symbols = get_symbol_iterator()
            main_color_sel = next(main_colors_it)
            # sec_color_sel = rgb_to_rgba(next(sec_colors_it), 0.2)
            for noise in enabled_noise:
                symbol = next(symbols)

                coeff_mean_metric_values = (
                    coeffs_df[
                        (coeffs_df.ansatz == ansatz)
                        & (coeffs_df.qubits == qubit)
                        & (coeffs_df.noise_level == noise_level)
                    ]
                    .groupby(noise)[f"coeffs_abs_mean"]
                    .agg(["mean", "min", "max"])
                )
                frequencies_mean_metric_values = (
                    coeffs_df[
                        (coeffs_df.ansatz == ansatz)
                        & (coeffs_df.qubits == qubit)
                        & (coeffs_df.noise_level == noise_level)
                    ]
                    .groupby(noise)[f"frequencies"]
                    .agg(["mean"])
                )

                fig.add_trace(
                    go.Scatter(
                        x=frequencies_mean_metric_values["mean"].item(),
                        y=coeff_mean_metric_values["mean"].item(),
                        name=f"{qubit} Qubits - {noise} Mean - {noise_level:.2f}",
                        mode="lines",
                        line=dict(color=main_color_sel),
                        marker=dict(color=main_color_sel),
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

        fig.update_yaxes(title_text=f"Magnitude", secondary_y=False)
        fig.update_xaxes(title_text="Frequency")
        fig.update_layout(
            title=f"{ansatz.title()} - {qubit} Qubits - Spectrogram",
            template="plotly_white",
            yaxis_type="log",
            # legend=dict(x=1.2),
            width=1200,
        )
        fig.show()
        save_fig(
            fig,
            f"{qubit}_{ansatz.lower()}_level",
            run_ids,
            experiment_id,
        )
