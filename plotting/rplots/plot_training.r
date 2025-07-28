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

data_path <- "csv_data/training.csv"

d <- read_csv(data_path)

d <- d %>%
    pivot_longer(
        c(
            BitFlip, PhaseFlip, Depolarizing,
            AmplitudeDamping, PhaseDamping,
            StatePreparation, Measurement, GateError
        ),
        names_to = "noise_type", values_to = "noise_value"
    ) %>%
    filter(!is.na(noise_value))

d <- d %>%
    mutate(coeff_abs = sqrt(coeffs_real^2 + coeffs_imag^2)) %>%
    group_by(noise_type, noise_value, ansatz, qubits, frequencies, step, problem_seed) %>%
    summarise(
        mean_coeff_abs = mean(coeff_abs),
        sd_coeff_abs = sd(coeff_abs),
        mean_mse = mean(mse),
        sd_mse = sd(mse),
        mean_dist = mean(coeff_dist),
        sd_dist = sd(coeff_dist),
    ) %>%
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
        noise_value = round(noise_value, digits = 3),
        coeff_lower_bound = mean_coeff_abs - sd_coeff_abs,
        coeff_upper_bound = mean_coeff_abs + sd_coeff_abs,
        mse_lower_bound = mean_mse - sd_mse,
        mse_upper_bound = mean_mse + sd_mse,
        dist_lower_bound = mean_dist - sd_dist,
        dist_upper_bound = mean_dist + sd_dist,
    )

d$noise_category <- factor(d$noise_category, levels = c("", "Decoherent Gate", "SPAM", "Damping", "Coh."))
d$noise_type <- factor(d$noise_type,
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

d$ansatz <- factor(d$ansatz,
    levels = c("Strongly_Entangling", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "HEA", "Circuit 15", "Circuit 19")
)

d$noise_type[d$noise_value == 0] <- "Noiseless"
d$noise_category[d$noise_value == 0] <- ""

d <- d %>% distinct(noise_category, noise_type, ansatz, qubits, frequencies, step, problem_seed, .keep_all = TRUE)

g <- ggplot(
    d,
    aes(x = step, y = mean_coeff_abs, colour = as.factor(frequencies))
) +
    # geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = coeff_lower_bound, ymax = coeff_upper_bound, fill = as.factor(frequencies)), alpha = 0.2, colour = NA) +
    scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
    facet_nested(noise_category + noise_type ~ problem_seed + ansatz) +
    scale_x_continuous("Step") +
    scale_y_continuous("c") +
    theme_paper() +
    theme(
        legend.margin = margin(b = -4)
    )
save_name <- str_c("training_coeffs")
create_plot(g, save_name, COLWIDTH, 0.7 * HEIGHT)

d <- d %>%
    group_by(noise_category, noise_type, ansatz, qubits, step, problem_seed) %>%
    summarise(
        mean_mse = mean(mean_mse),
        sd_mse = mean(sd_mse),
        mean_dist = mean(mean_dist),
        sd_dist = mean(mean_dist)
    ) %>%
    mutate(
        mse_lower_bound = mean_mse - sd_mse,
        mse_upper_bound = mean_mse + sd_mse,
        dist_lower_bound = mean_dist - sd_dist,
        dist_upper_bound = mean_dist + sd_dist,
    )

g <- ggplot(
    d,
    aes(x = step, y = mean_mse, colour = as.factor(qubits))
) +
    # geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = mse_lower_bound, ymax = mse_upper_bound, fill = as.factor(qubits)), alpha = 0.2, colour = NA) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(noise_category + noise_type ~ problem_seed + ansatz) +
    scale_x_continuous("MSE") +
    scale_y_continuous("c") +
    theme_paper() +
    theme(
        legend.margin = margin(b = -4)
    )
save_name <- str_c("training_mse")
create_plot(g, save_name, COLWIDTH, 0.7 * HEIGHT)

g <- ggplot(
    d,
    aes(x = step, y = mean_dist, colour = as.factor(qubits))
) +
    # geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = dist_lower_bound, ymax = dist_upper_bound, fill = as.factor(qubits)), alpha = 0.2, colour = NA) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    facet_nested(noise_category + noise_type ~ problem_seed + ansatz) +
    scale_x_continuous("Step") +
    scale_y_continuous("Coefficient Distance") +
    theme_paper() +
    theme(
        legend.margin = margin(b = -4)
    )
save_name <- str_c("training_coeff_dist")
create_plot(g, save_name, COLWIDTH, 0.7 * HEIGHT)
