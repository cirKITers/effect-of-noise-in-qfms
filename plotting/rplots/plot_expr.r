#!/usr/bin/env Rscript

library(tidyverse)
library(ggh4x)
library(tikzDevice)
library(scales)
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

coeffs_path <- "csv_data/expr.csv"
d_expr <- read_csv(coeffs_path)

d_expr$ansatz <- ansatz_to_factor(d_expr$ansatz)

d_expr <- d_expr %>%
    pivot_longer(
        c(
            BitFlip, PhaseFlip, Depolarizing,
            AmplitudeDamping, PhaseDamping, GateError,
            StatePreparation, Measurement,
        ),
        names_to = "noise_type", values_to = "noise_value"
    ) %>%
    distinct(noise_type, noise_value, ansatz, qubits, seed, .keep_all = TRUE) %>%
    group_by(noise_type, noise_value, ansatz, qubits) %>%
    summarise(
        mean_expr = mean(expressibility),
        sd_expr = sd(expressibility),
        min_expr = min(expressibility),
        max_expr = max(expressibility)
    ) %>%
    mutate(
        upper_bound = max_expr,
        lower_bound = min_expr
    )

print(
  str_c(
    "Mean relative standard deviation: ",
    mean(d_expr$sd_expr / d_expr$mean_expr)
  )
)

d_expr <- d_expr %>%
    filter(!is.na(noise_value) & noise_value <= 0.03) %>%
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
                    "Coh."
                )
            )
        ),
    )

d_expr$noise_category <- factor(d_expr$noise_category, levels = c("Decoherent Gate", "Coherent", "SPAM", "Damping", "Coh."))

d_expr$noise_type <- factor(d_expr$noise_type,
    levels = c(
        "Noiseless", "BitFlip", "PhaseFlip", "Depolarizing",
        "AmplitudeDamping", "PhaseDamping",
        "StatePreparation", "Measurement",
        "GateError"
    ),
    labels = c(
        "Noiseless", "BF", "PF", "DP",
        "AD", "PD",
        "SP", "ME",
        "GE"
    ),
)

kl_max = max(d_expr$upper_bound)
kl_min = min(d_expr$lower_bound)

g <- ggplot(
    d_expr,
    aes(x = noise_value, y = mean_expr, colour = as.factor(qubits))
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    geom_hline(aes(linetype="", yintercept = kl_max), linewidth = LINE.SIZE, colour = COLOURS.LIST[6]) +
    geom_hline(aes(linetype="", yintercept = kl_min), linewidth = LINE.SIZE, colour = COLOURS.LIST[6]) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    scale_y_log10(
        ifelse(use_tikz, "\\quad \\scriptsize{more expr.} \\normalsize{$\\leftarrow$    KL-Divergence [log]    $\\rightarrow$} \\scriptsize{less expr.}", "KL-Divergence [log]"),
        breaks = c(1e-2, 1e0, 1e2),
        labels = trans_format("log10", math_format(10^.x)),
    ) +
    scale_linetype_manual("Min/Max", values=c("11", "11")) +
    theme(
        legend.margin = margin(b = -4),
    )

save_name <- str_c("expr")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)
