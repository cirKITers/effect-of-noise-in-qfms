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

index_labeller <- function(layer) {
    paste0("i = ", layer)
}

# d_expr$ansatz <- gsub("_", " ", d_expr$ansatz)
d_expr$ansatz <- factor(d_expr$ansatz,
    levels = c("Strongly_Entangling", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "HEA", "Circuit 15", "Circuit 19")
)

d_expr <- d_expr %>%
    filter(seed < 1005) %>%
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
        # upper_bound = mean_expr + sd_expr,
        # lower_bound = mean_expr - sd_expr
        upper_bound = max_expr,
        lower_bound = min_expr
    )

d_expr <- d_expr %>%
    filter(!is.na(noise_value)) %>%
    filter(noise_value <= 0.03) %>%
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

d_expr$noise_category <- factor(d_expr$noise_category, levels = c("Decoherent Gate", "Coherent", "SPAM", "Damping"))

d_expr$noise_type <- factor(d_expr$noise_type,
    levels = c(
        "Noiseless", "BitFlip", "PhaseFlip", "Depolarizing",
        "AmplitudeDamping", "PhaseDamping",
        "StatePreparation", "Measurement",
        "GateError"
    ),
    labels = c(
        "Noiseless", "BF", "PF", "Depol.",
        "AD", "PD",
        "SP", "Meas.",
        "Gate Error"
    ),
)

d_7_qubits <- d_expr %>%
    filter(qubits == 7)

gate_noise_scale <- scale_y_log10(
    "KL-Divergence [log]",
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = trans_format("log10", math_format(10^.x)),
    limits = c(10e-4, 130),
)
gate_noise_scale_no_guide <- scale_y_log10(
    "KL-Divergence",
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = trans_format("log10", math_format(10^.x)),
    limits = c(10e-4, 130),
    guide = "none"
)

spam_noise_scale <- scale_y_log10(
    "KL-Divergence [log]",
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = trans_format("log10", math_format(10^.x)),
    limits = c(10e-4, 2)
)

spam_noise_scale_no_guide <- scale_y_log10(
    guide = "none",
    limits = c(10e-4, 2)
)

env_noise_scale <- scale_y_continuous(
    "KL-Divergence",
    limits = c(0, 1)
)

env_noise_scale_no_guide <- scale_y_continuous(
    guide = "none",
    limits = c(0, 1)
)


g <- ggplot(
    d_expr,
    aes(x = noise_value, y = mean_expr, colour = as.factor(qubits))
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound, fill = as.factor(qubits)), alpha = 0.5, colour = NA) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(noise_category + noise_type ~ ansatz,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
        scale = "free_y",
        #independent = "y",
    ) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    scale_y_log10(
        "KL-Divergence [log]",
        breaks = scales::trans_breaks("log10", function(x) 10^(-3:3)),
        labels = trans_format("log10", math_format(10^.x)),
    ) +
    theme(legend.margin = margin(b=-4))

save_name <- str_c("expr")
create_plot(g, save_name, COLWIDTH, 0.5 * HEIGHT)
