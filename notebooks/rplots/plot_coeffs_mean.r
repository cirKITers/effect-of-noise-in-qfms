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
    filter(ansatz != "Strongly_Entangling_Plus" & coeffs_abs_mean > 1e-14) %>%
    group_by(
        BitFlip, PhaseFlip, Depolarizing,
        AmplitudeDamping, PhaseDamping,
        StatePreparation, Measurement, GateError,
        ansatz, qubits, n_input_feat, freq1
    ) %>%
    summarise(
        mean_abs = mean(coeffs_abs_mean),
        sd_mean_abs = sd(coeffs_abs_mean),
        rel_sd_mean_abs = sd(coeffs_abs_mean) / mean(coeffs_abs_mean),
        sd_abs = mean(sqrt(coeffs_abs_var)),
    ) %>%
    mutate(
        upper_bound = mean_abs + sd_abs,
        lower_bound = mean_abs - sd_abs,
        rel_sd = sd_abs / mean_abs,
        max_freq = max(freq1),
        freq2 = 0
    )

d_coeffs_2D <- d_coeffs_2D %>%
    filter(ansatz != "SEA+" & coeffs_abs_mean > 1e-14) %>%
    group_by(
        BitFlip, PhaseFlip, Depolarizing,
        AmplitudeDamping, PhaseDamping,
        StatePreparation, Measurement, GateError,
        ansatz, qubits, n_input_feat, freq1, freq2
    ) %>%
    summarise(
        mean_abs = mean(coeffs_abs_mean),
        sd_mean_abs = sd(coeffs_abs_mean),
        rel_sd_mean_abs = sd(coeffs_abs_mean) / mean(coeffs_abs_mean),
        sd_abs = mean(sqrt(coeffs_abs_var)),
        max_freq = max(freq1)
    ) %>%
    mutate(
        upper_bound = mean_abs + sd_abs,
        lower_bound = mean_abs - sd_abs,
        rel_sd = sd_abs / mean_abs,
        max_freq1 = max(freq1),
        max_freq2 = max(freq2)
    )
d_coeffs_1D <- d_coeffs_1D %>% filter(freq1 == max_freq | freq1 == 0)
d_coeffs_2D <- d_coeffs_2D %>% filter(freq1 == max_freq1 & freq2 == max_freq2 | freq1 == 0 & freq2 == 0)

d_coeffs <- rbind(d_coeffs_1D, d_coeffs_2D) %>%
    filter(qubits < 7) %>%
    mutate(coeff_type = ifelse(freq1 == 0, ifelse(use_tikz, "$0$", "0"), "max"))

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
    distinct(noise_type, noise_value, ansatz, qubits, n_input_feat, coeff_type, .keep_all = TRUE) %>%
    filter(noise_type %in% c("Depolarizing", "Measurement", "AmplitudeDamping", "GateError"))

d_coeffs$noise_type <- factor(d_coeffs$noise_type,
    levels = c(
        "BitFlip", "PhaseFlip", "Depolarizing",
        "AmplitudeDamping", "PhaseDamping",
        "StatePreparation", "Measurement",
        "GateError"
    ),
    labels = c(
        "BF", "PF", "DP",
        "AD", "PD",
        "SP", "ME",
        "CGE"
    ),
)

d_coeffs$ansatz <- factor(d_coeffs$ansatz,
    levels = c("Strongly_Entangling", "Strongly_Entangling_Plus", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "SEA+", "HEA", "Circuit 15", "Circuit 19")
)

g <- ggplot(
    d_coeffs,
    aes(x = noise_value, y = mean_abs, colour = as.factor(qubits), shape = coeff_type, linetype = coeff_type)
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_linetype_manual(ifelse(use_tikz, "$\\omega$", ""), values = c("solid", "11")) +
    scale_shape_manual(ifelse(use_tikz, "$\\omega$", ""), values = c(4, 17)) +
    facet_nested(coeff_type + noise_type ~ ansatz + n_input_feat,
        labeller = labeller(
            freq1 = frequencies_labeller,
            qubits = qubit_labeller,
            n_input_feat = feature_labeller,
            coeff_type = frequencies_labeller,
        ),
        scale = "free_y",
        independent = "y"
    ) +
    scale_x_continuous("Noise Level",
        labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)
    ) +
    theme_paper() +
    guides(
        colour = guide_legend(nrow = 1),
        shape = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE))
    ) +
    theme(
        legend.margin = margin(b = -4)
    ) +
    facetted_pos_scales(
        y = list(
            ansatz == "SEA" & n_input_feat == 1 & coeff_type == ifelse(use_tikz, "$0$", "0") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c(\\omega)$ [log]", "|c| Mean [log]"),
                breaks = scales::trans_breaks("log10", function(x) 10^(-3:-1)),
                labels = trans_format("log10", math_format(10^.x)),
                trans = "log10",
                limits = c(1e-3, 1e-1)
            ),
            ansatz != "SEA" & coeff_type == ifelse(use_tikz, "$0$", "0") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c(\\omega)$ [log]", "|c| Mean [log]"),
                breaks = scales::trans_breaks("log10", function(x) 10^(-3:-1)),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(1e-3, 1e-1),
                trans = "log10",
                guide = "none"
            ),
            ansatz == "SEA" & n_input_feat != 1 & coeff_type == ifelse(use_tikz, "$0$", "0") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c(\\omega)$ [log]", "|c| Mean [log]"),
                breaks = scales::trans_breaks("log10", function(x) 10^(-3:-1)),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(1e-3, 1e-1),
                trans = "log10",
                guide = "none"
            ),
            ansatz == "SEA" & n_input_feat == 1 & coeff_type == "max" ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c(\\omega)$ [log]", "|c| Mean [log]"),
                breaks = c(1e-8, 1e-6, 1e-4, 1e-2),
                labels = trans_format("log10", math_format(10^.x)),
                trans = "log10",
                limits = c(1e-8, 5e-2)
            ),
            ansatz != "SEA" & coeff_type == "max" ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c(\\omega)$ [log]", "|c| Mean [log]"),
                breaks = c(1e-8, 1e-6, 1e-4, 1e-2),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(1e-8, 5e-2),
                trans = "log10",
                guide = "none"
            ),
            ansatz == "SEA" & n_input_feat != 1 & coeff_type == "max" ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c(\\omega)$ [log]", "|c| Mean [log]"),
                breaks = c(1e-8, 1e-6, 1e-4, 1e-2),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(1e-8, 5e-2),
                trans = "log10",
                guide = "none"
            )
        )
    )
save_name <- str_c("coeff_abs_mean")
create_plot(g, save_name, COLWIDTH, 0.4 * HEIGHT)
print(warnings())

g <- ggplot(
    d_coeffs,
    aes(x = noise_value, y = rel_sd, colour = as.factor(qubits), shape = coeff_type, linetype = coeff_type)
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(coeff_type + noise_type ~ ansatz + n_input_feat,
        labeller = labeller(
            freq1 = frequencies_labeller,
            n_input_feat = feature_labeller,
            qubits = qubit_labeller,
            coeff_type = frequencies_labeller,
        ),
        scale = "free_y"
    ) +
    scale_linetype_manual("", values = c("solid", "11")) +
    scale_shape_manual("", values = c(4, 17)) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
    scale_y_continuous(ifelse(use_tikz, "$\\sigma_c(\\omega)$", "|c| Relative Standard Deviation"), ) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1), shape = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE))) +
    theme(
        legend.margin = margin(b = -4)
    )
save_name <- str_c("coeff_abs_sd")
create_plot(g, save_name, COLWIDTH, 0.4 * HEIGHT)
