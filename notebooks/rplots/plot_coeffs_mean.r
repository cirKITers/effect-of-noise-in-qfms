#!/usr/bin/env Rscript

library(tidyverse)
library(ggh4x)
library(tikzDevice)
library(scales)
library(ggrastr)
source("layout.r")

options(tikzLatexPackages = c(
    getOption("tikzLatexPackages"),
    "\\usepackage{amsmath}"
))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1) {
    use_tikz <- FALSE
    POINT.SIZE <- 0.4
    LINE.SIZE <- 0.4
}

coeffs_path <- "csv_data/coeffs_full.csv"

d_coeffs <- read_csv(coeffs_path)

index_labeller <- function(layer) {
    paste0("i = ", layer)
}

d_coeffs$ansatz <- factor(d_coeffs$ansatz,
  levels = c("Strongly_Entangling", "Strongly_Entangling_Plus", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
  labels = c("SEA", "SEA+", "HEA", "Circuit 15", "Circuit 19")
)

d_coeffs <- d_coeffs %>%
    filter(ansatz != "SEA+") %>%
    mutate(
        coeffs_abs = sqrt(coeffs_full_real^2 + coeffs_full_imag^2),
    ) %>%
    group_by(
        BitFlip, PhaseFlip, Depolarizing,
        AmplitudeDamping, PhaseDamping,
        StatePreparation, Measurement, GateError,
        ansatz, qubits, frequencies
    ) %>%
    # Filter zero coefficients
    filter(coeffs_abs > 1e-14) %>%
    summarise(
        mean_abs_coeff = mean(coeffs_abs),
        sd_abs_coeff = sd(coeffs_abs),
    )

d_coeffs <- d_coeffs %>%
    pivot_longer(
        c(
            BitFlip, PhaseFlip, Depolarizing,
            AmplitudeDamping, PhaseDamping,
            StatePreparation, Measurement, GateError
        ),
        names_to = "noise_type", values_to = "noise_value"
    ) %>%
    filter(!is.na(noise_value) & noise_value < 0.1)

d_coeffs <- d_coeffs %>%
    distinct(noise_type, noise_value, ansatz, qubits, .keep_all = TRUE) %>%
    mutate(
        noise_category = ifelse(
            noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
            "Decoherent Gate",
            ifelse(
                noise_type %in% c("StatePreparation", "Measurement"),
                "SPAM",
                ifelse(
                    noise_type %in% c("AmplitudeDamping", "PhaseDamping"),
                    "Damping",
                    "Coherent"
                )
            )
        ),
    )
d_coeffs$noise_category <- factor(d_coeffs$noise_category, levels = c("Decoherent Gate", "Coherent", "SPAM", "Damping"))

d_coeffs$noise_type <- factor(d_coeffs$noise_type,
    levels = c(
        "Noiseless", "BitFlip", "PhaseFlip", "Depolarizing",
        "AmplitudeDamping", "PhaseDamping",
        "StatePreparation", "Measurement",
        "GateError"
    ),
    labels = c(
        "Noiseless", "Bit Flip", "Phase Flip", "Depolarising",
        "Amplitude Damping", "Phase Damping",
        "State Preparation", "Measurement",
        "Gate Error"
    ),
)

g <- ggplot(
    d_coeffs,
    aes(x = noise_value, y = mean_abs_coeff, colour = as.factor(qubits))
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type,
        labeller = labeller(
            frequencies = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_x_continuous("Noise Probability", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
    scale_y_log10(ifelse(use_tikz, "$\\bar{\\lvert{c}\\rvert}$ [log]", "|c| Mean [log]"),
        breaks = scales::trans_breaks("log10", function(x) 10^x),
        labels = trans_format("log10", math_format(10^.x))
    ) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    theme(
        legend.margin = margin(b = -1)
    )
save_name <- str_c("coeff_abs_mean")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)

g <- ggplot(
    d_coeffs,
    aes(x = noise_value, y = sd_abs_coeff, colour = as.factor(qubits))
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type,
        labeller = labeller(
            frequencies = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_x_continuous("Noise Probability", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
    scale_y_log10(ifelse(use_tikz, "$\\sigma(\\lvert{c}\\rvert)$ [log]", "|c| Standard Deviation [log]"),
        breaks = scales::trans_breaks("log10", function(x) 10^x),
        labels = trans_format("log10", math_format(10^.x))
    ) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    theme(
        legend.margin = margin(b = -1)
    )
save_name <- str_c("coeff_abs_sd")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)
