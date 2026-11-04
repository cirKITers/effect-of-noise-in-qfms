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

# Histogram bins per qubit, see conf/base/parameters.yml (expressibility.n_bins).
# qml_essentials scales this with the number of qubits (scale=True), i.e. the
# actual number of bins is N.BINS * qubits.
N.BINS <- 75
# Differences to the upper bound below this threshold are float rounding
# noise and treated as "bound reached exactly".
DIFF.EPS <- 1e-6

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
    distinct(noise_type, noise_value, ansatz, qubits, layers, seed, .keep_all = TRUE) %>%
    # Upper bound of the KL divergence to the Haar distribution: all sampled
    # fidelities fall into the last (least probable) Haar bin, so
    # KL_max = -log(q_min) = (2^qubits - 1) * log(number of bins).
    mutate(
        kl_max = (2^qubits - 1) * log(N.BINS * qubits),
        diff_expr = kl_max - expressibility,
        diff_expr = ifelse(diff_expr < DIFF.EPS, 0, diff_expr)
    ) %>%
    group_by(noise_type, noise_value, ansatz, qubits, layers, kl_max) %>%
    summarise(
        mean_expr = mean(expressibility),
        sd_expr = sd(expressibility),
        min_expr = min(expressibility),
        max_expr = max(expressibility),
        mean_diff = mean(diff_expr),
        min_diff = min(diff_expr),
        max_diff = max(diff_expr)
    ) %>%
    mutate(
        upper_bound = max_expr,
        lower_bound = min_expr
    )

print(
  str_c(
    "Max relative standard deviation: ",
    max(d_expr$sd_expr / d_expr$mean_expr)
  )
)

d_expr <- d_expr %>%
    filter(!is.na(noise_value) & noise_value <= 0.03) %>%
    mutate(
        noise_category = ifelse(
            noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
            "Decoherent",
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

d_expr$noise_category <- factor(d_expr$noise_category, levels = c("", "Decoherent", "Coherent", "SPAM", "Damping", "Coh."))

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
        "CGE"
    ),
)

g <- ggplot(
    d_expr %>% filter(layers==1),
    aes(x = noise_value, y = mean_expr, colour = as.factor(qubits))
) +
    geom_point(size = POINT.SIZE) +
    geom_hline(aes(linetype="", yintercept = kl_max, colour = as.factor(qubits)), linewidth = LINE.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
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
    scale_linetype_manual("Upper Bound", values=c("11")) +
    theme(
        legend.margin = margin(b = -4),
    )

save_name <- str_c("expr")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

d_expr <- d_expr %>% filter(noise_value %in% c(0, 0.03))
d_expr$noise_type[d_expr$noise_value == 0] <- "Noiseless"
d_expr <- d_expr %>% distinct(noise_type, noise_value, ansatz, qubits, layers, .keep_all = TRUE)
d_expr$noise_category[d_expr$noise_type == "Noiseless"] <- ""

d_expr <- d_expr %>% mutate(at_bound = ifelse(mean_diff == 0, "", NA))

g <- ggplot(
    d_expr,
    aes(x = layers, y = mean_expr, colour = as.factor(qubits))
) +
    geom_point(size = POINT.SIZE) +
    geom_hline(aes(linetype="", yintercept = kl_max, colour = as.factor(qubits)), linewidth = LINE.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_x_continuous(ifelse(use_tikz, "\\# Layers", "# Layers")) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    scale_y_log10(
        ifelse(use_tikz, "\\quad \\scriptsize{more expr.} \\normalsize{$\\leftarrow$    KL-Divergence [log]    $\\rightarrow$} \\scriptsize{less expr.}", "KL-Divergence [log]"),
        breaks = c(1e-2, 1e0, 1e2),
        labels = trans_format("log10", math_format(10^.x)),
    ) +
    scale_linetype_manual("Upper Bound", values=c("11")) +
    theme(
        legend.margin = margin(b = -4),
    )

save_name <- str_c("expr_layers")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)
