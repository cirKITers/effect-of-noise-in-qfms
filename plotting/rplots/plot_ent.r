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

d_ent$ansatz <- factor(d_ent$ansatz,
    levels = c("Strongly_Entangling", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "HEA", "Circuit 15", "Circuit 19")
)
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

d_ent <- d_ent %>%
    filter(!is.na(noise_value) & (noise_value == 0 | noise_value > 0.0045)) %>%
    mutate(
        noise_category = ifelse(
            noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
            "Decoherent Gate",
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

d_ent$noise_category <- factor(d_ent$noise_category, levels = c("Decoherent Gate", "SPAM", "Damping", "Coh."))

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

d_ent <- d_ent %>% filter(measure == "EF" | noise_value == 0)
d_ent$measure <- factor(d_ent$measure, levels = c("MW", "EF"), labels = c("MW", "EF"))

g <- ggplot(
    d_ent,
    aes(x = noise_value, colour = as.factor(qubits), shape = measure)
) +
    geom_point(aes(y = mean_ent), size = POINT.SIZE) +
    geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound, fill = as.factor(qubits)), alpha = 0.5, colour = NA) +
    geom_line(aes(y = mean_ent), linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_shape_manual("Measure", values = c(4, 19)) +
    facet_nested(ansatz ~ noise_category + noise_type + measure,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
        scale = "free_x",
    ) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
    scale_y_log10("Entangling Capability [log]") +
    theme_paper() +
    guides(
        colour = guide_legend(nrow = 1),
        shape = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE))
    ) +
    theme(
        legend.margin = margin(b = -4),
        legend.key.height = unit(0.2, "cm"),
        legend.key.width = unit(0.2, "cm")
    ) +
    force_panelsizes(cols = c(4, 7)) +
    facetted_pos_scales(
        x = list(
            measure == "MW" ~ scale_x_continuous("Noise Level", limits = c(-0.001, 0.001), breaks = seq(-1, 1, 1), labels = ifelse(use_tikz, latex_percent, scales::percent))
        )
    )


save_name <- str_c("ent")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)


d_meyer_wallach <- d_ent %>%
    filter(measure == "MW" & noise_value == 0)

g <- ggplot(
    d_meyer_wallach,
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
    scale_y_continuous("MW Entanglement") +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1)) +
    theme(
        legend.margin = margin(b = -4),
        legend.key.height = unit(0.2, "cm"),
        legend.key.width = unit(0.2, "cm")
    )

save_name <- str_c("ent_mw")
create_plot(g, save_name, 0.5 * TEXTWIDTH, 0.15 * HEIGHT)
