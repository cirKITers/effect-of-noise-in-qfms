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

ent_path <- "csv_data/ent.csv"
d_ent <- read_csv(ent_path)

d_ent$ansatz <- ansatz_to_factor(d_ent$ansatz)

d_ent <- d_ent %>%
    pivot_longer(
        c(
            BitFlip, PhaseFlip, Depolarizing,
            AmplitudeDamping, PhaseDamping, GateError,
            StatePreparation, Measurement,
        ),
        names_to = "noise_type", values_to = "noise_value"
    ) %>%
    distinct(noise_type, noise_value, ansatz, qubits, seed, measure, .keep_all = TRUE) %>%
    group_by(noise_type, noise_value, ansatz, qubits, measure) %>%
    summarise(
        mean_ent = mean(entangling_capability),
        sd_ent = sd(entangling_capability),
        max_ent = max(entangling_capability),
        min_ent = min(entangling_capability)
    ) %>%
    mutate(
        upper_bound = max_ent,
        lower_bound = min_ent
    )

print(
  str_c(
    "Max relative standard deviation: ",
    max(d_ent$sd_ent / d_ent$mean_ent)
  )
)

d_ent <- d_ent %>%
    filter(!is.na(noise_value) & (noise_value == 0 | noise_value > 0.0045)) %>%
    mutate(
        noise_category = ifelse(
            noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
            "Decoherent",
            ifelse(
                noise_type %in% c("StatePreparation", "Measurement"),
                "SPAM",
                ifelse(noise_type == "GateError",
                    "Coh.",
                    "Damping"
                )
            )
        ),
    )

d_ent$noise_category <- factor(d_ent$noise_category, levels = c("Decoherent", "SPAM", "Damping", "Coh."))

d_ent$noise_type <- factor(d_ent$noise_type,
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

ent_label <- ifelse(use_tikz, "$\\overline{\\mathcal{N}}$", "Entanglement")

g <- ggplot(
    d_ent,
    aes(x = noise_value, colour = as.factor(qubits))
) +
    geom_point(aes(y = mean_ent), size = POINT.SIZE) +
    geom_line(aes(y = mean_ent), linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
        scale = "free_x",
    ) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
    scale_y_log10(str_c(ent_label, " [log]")) +
    theme_paper() +
    guides(
        colour = guide_legend(nrow = 1),
        shape = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE))
    ) +
    theme(
        legend.margin = margin(b = -4),
        plot.margin = margin(l=2)
    )


save_name <- str_c("ent")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

g <- ggplot(
  d_ent %>%
    filter(noise_value == 0),
    aes(x = ansatz, y = mean_ent, fill = as.factor(qubits))
) +
    geom_bar(stat = "identity", position = position_dodge(), width = 0.7) +
    geom_errorbar(aes(ymin = min_ent, ymax = max_ent),
        width = .1,
        position = position_dodge(.7),
        colour = COLOURS.LIST[6]
    ) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_x_discrete("") +
    scale_y_continuous(ent_label) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    theme(
        legend.margin = margin(b = -4),
        plot.margin = margin(l=2)
    )

save_name <- str_c("ent_noiseless")
create_plot(g, save_name, 0.5 * TEXTWIDTH, 0.15 * HEIGHT)
