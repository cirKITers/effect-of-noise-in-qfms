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

coeffs_path_1D <- "csv_data/coeffs_stat_dims1.csv"
coeffs_path_2D <- "csv_data/coeffs_stat_dims2.csv"

d_coeffs_1D <- read_csv(coeffs_path_1D)
d_coeffs_2D <- read_csv(coeffs_path_2D)

d_coeffs_1D <- d_coeffs_1D %>%
    filter(ansatz != "Strongly_Entangling_Plus") %>%
    pivot_longer(
        c(
            BitFlip, PhaseFlip, Depolarizing,
            AmplitudeDamping, PhaseDamping,
            StatePreparation, Measurement, GateError
        ),
        names_to = "noise_type", values_to = "noise_value"
    ) %>%
    filter(!is.na(noise_value) & noise_type == "GateError") %>%
    distinct(noise_value, ansatz, qubits, seed, freq1, .keep_all = TRUE) %>%
    group_by(
        noise_value, ansatz, qubits, seed, n_input_feat,
    ) %>%
    # Filter zero coefficients
    filter(coeffs_abs_mean > 1e-15) %>%
    summarise(
        n_freqs = n(),
        mean_abs = mean(coeffs_abs_mean),
        mean_sd = mean(sqrt(coeffs_abs_var)),
    ) %>%
    group_by(
        noise_value, ansatz, qubits, n_input_feat,
    ) %>%
    summarise(
        mean_abs = mean(mean_abs),
        mean_sd = mean(mean_sd),
        n_freqs = (median(n_freqs) - 1) * 2 + 1,
    ) %>%
    mutate(max_freq = 2 * qubits + 1)


d_coeffs_2D <- d_coeffs_2D %>%
    pivot_longer(
        c(
            BitFlip, PhaseFlip, Depolarizing,
            AmplitudeDamping, PhaseDamping,
            StatePreparation, Measurement, GateError
        ),
        names_to = "noise_type", values_to = "noise_value"
    ) %>%
    filter(!is.na(noise_value) & noise_type == "GateError") %>%
    distinct(noise_value, ansatz, qubits, seed, freq1, freq2, .keep_all = TRUE) %>%
    group_by(
        noise_value, ansatz, qubits, seed, n_input_feat,
    ) %>%
    # Filter zero coefficients
    filter(coeffs_abs_mean > 1e-15) %>%
    summarise(
        n_freqs = n(),
        mean_abs = mean(coeffs_abs_mean),
        mean_sd = mean(sqrt(coeffs_abs_var)),
    ) %>%
    group_by(
        noise_value, ansatz, qubits, n_input_feat,
    ) %>%
    summarise(
        mean_abs = mean(mean_abs),
        mean_sd = mean(mean_sd),
        n_freqs = median(n_freqs),
    ) %>%
    mutate(max_freq = (2 * qubits + 1)^2)

d_coeffs <- rbind(d_coeffs_1D, d_coeffs_2D) %>% filter(qubits < 7 & noise_value < 0.1 & ansatz %in% c("Hardware_Efficient", "Circuit_15"))
d_coeffs$ansatz <- factor(d_coeffs$ansatz,
    levels = c("Strongly_Entangling", "Strongly_Entangling_Plus", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "SEA+", "HEA", "Circuit 15", "Circuit 19")
)

d_coeffs_n <- d_coeffs %>%
    mutate(noise_value = round(noise_value, digits = 3)) %>%
    filter(noise_value %in% c(0, 0.01))
d_coeffs_n$noise_value <- factor(d_coeffs_n$noise_value, labels = c("Noiseless", "Coherent Error"))

g <- ggplot(
    d_coeffs_n,
    aes(x = as.factor(qubits), y = n_freqs, fill = noise_value)
) +
    geom_hline(aes(yintercept = max_freq, colour = as.factor(qubits)), linetype = "dashed", linewidth = LINE.SIZE) +
    geom_bar(stat = "identity", position = position_dodge(), width = 0.7) +
    geom_line(linewidth = LINE.SIZE) +
    scale_fill_manual("", values = c(COLOURS.LIST[7], COLOURS.LIST[6])) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits -- Limit", "# Qubits -- Limit"), values = COLOURS.LIST) +
    facet_nested(n_input_feat ~ ansatz,
        labeller = labeller(
            n_input_feat = feature_labeller,
            qubits = qubit_labeller,
        ),
        scale = "free_y"
    ) +
    scale_x_discrete(ifelse(use_tikz, "\\# Qubits", "# Qubits")) +
    scale_y_continuous(ifelse(use_tikz, "$\\lvert \\Omega \\rvert$", "# Frequencies")) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1, theme = theme(
        legend.byrow = TRUE,
    ))) +
    theme(
        legend.margin = margin(b = -4),
        legend.key.height = unit(0.2, "cm"),
        legend.key.width = unit(0.2, "cm")
    )
save_name <- str_c("n_freqs")
create_plot(g, save_name, COLWIDTH, 0.17 * HEIGHT)

g <- ggplot(
    d_coeffs,
    aes(x = noise_value, y = mean_abs, colour = as.factor(qubits))
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(n_input_feat ~ ansatz,
        labeller = labeller(
            n_input_feat = feature_labeller,
            qubits = qubit_labeller,
        ),
        scale = "free_y"
    ) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
    scale_y_log10(ifelse(use_tikz, "$\\bar{\\lvert{c}\\rvert}$ [log]", "|c| Mean [log]"),
        breaks = scales::trans_breaks("log10", function(x) 10^x),
        labels = trans_format("log10", math_format(10^.x))
    ) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    theme(
        legend.margin = margin(b = -4),
        legend.key.width = unit(0.3, "cm")
    )
save_name <- str_c("coeff_abs_mean_coherent")
create_plot(g, save_name, 0.5 * COLWIDTH, 0.2 * HEIGHT)
