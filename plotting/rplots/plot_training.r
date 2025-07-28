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


d$noise_type[d$noise_value == 0] <- "Noiseless"

d <- d %>%
    distinct(noise_type, noise_value, ansatz, qubits, frequencies, step, problem_seed, seed, .keep_all = TRUE) %>%
    mutate(
        coeff_abs = sqrt(coeffs_real^2 + coeffs_imag^2),
        abs_target = sqrt(target_coefficients_real^2 + target_coefficients_imag^2),
        coeff_abs_dist = abs(coeff_abs - abs_target),
        noise_category = ifelse(
            noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
            "Decoherent Gate",
            ifelse(
                noise_type %in% c("StatePreparation", "Measurement"),
                "SPAM",
                ifelse(
                    noise_type %in% c("AmplitudeDamping", "PhaseDamping"),
                    "Damping",
                    ifelse(
                        noise_type == "GateError",
                        "Coh.",
                        ""
                    )
                )
            )
        ),
        noise_value = round(noise_value, digits = 3),
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



d_summarised_freq <- d %>%
    group_by(noise_category, noise_type, ansatz, qubits, step, frequencies) %>%
    summarise(
        mean_abs_dist = mean(coeff_abs_dist),
        sd_abs_dist = sd(coeff_abs_dist),
    ) %>%
    mutate(
        dist_lower_bound = mean_abs_dist - sd_abs_dist,
        dist_upper_bound = mean_abs_dist + sd_abs_dist,
    )


d <- d %>%
    group_by(noise_category, noise_type, noise_value, ansatz, qubits, frequencies, step, problem_seed) %>%
    summarise(
        abs_target = mean(abs_target),
        mean_coeff_abs = mean(coeff_abs),
        sd_coeff_abs = sd(coeff_abs),
        mean_abs_dist = mean(coeff_abs_dist),
        sd_abs_dist = sd(coeff_abs_dist),
        mean_mse = mean(mse),
        sd_mse = sd(mse),
        mean_dist = mean(coeff_dist),
        sd_dist = sd(coeff_dist),
    ) %>%
    mutate(
        coeff_lower_bound = mean_coeff_abs - sd_coeff_abs,
        coeff_upper_bound = mean_coeff_abs + sd_coeff_abs,
    )

d_summarised <- d %>%
    group_by(noise_category, noise_type, ansatz, qubits, step) %>%
    summarise(
        mean_mse = mean(mean_mse),
        sd_mse = mean(sd_mse),
        mean_dist = mean(mean_dist),
        sd_dist = mean(sd_dist)
    ) %>%
    mutate(
        mse_lower_bound = mean_mse - sd_mse,
        mse_upper_bound = mean_mse + sd_mse,
        dist_lower_bound = mean_dist - sd_dist,
        dist_upper_bound = mean_dist + sd_dist,
    )

g <- ggplot(
    d_summarised_freq,
    aes(x = step, y = mean_abs_dist, colour = as.factor(frequencies))
) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = dist_lower_bound, ymax = dist_upper_bound, fill = as.factor(frequencies)), alpha = 0.2, colour = NA) +
    scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type,
        scale = "free_y"
    ) +
    scale_x_continuous("Step", breaks = seq(0, 1000, 500)) +
    scale_y_continuous("Coefficient Distance") +
    theme_paper() +
    theme(
        legend.margin = margin(b = -4)
    ) +
    guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)))
save_name <- str_c("training_coeff_dist")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

g <- ggplot(
    d_summarised,
    aes(x = step, y = mean_mse, colour = noise_category, linetype = noise_type)
) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = mse_lower_bound, ymax = mse_upper_bound), fill = "black", alpha = 0.2, colour = NA) +
    scale_colour_manual("", values = COLOURS.LIST) +
    scale_fill_manual("", values = COLOURS.LIST) +
    scale_linetype_manual("", values = c(1, 1, 2, 3, 1, 2, 1, 2, 1)) +
    facet_nested(. ~ ansatz) +
    scale_x_continuous("Step", breaks = seq(0, 1000, 500)) +
    scale_y_continuous("MSE") +
    theme_paper() +
    theme(
        legend.margin = margin(b = -4),
        legend.key.height = unit(0.2, "cm"),
        legend.key.width = unit(0.2, "cm")
    ) +
    guides(
        linetype = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(
            colour = c(COLOURS.LIST[1], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[3], COLOURS.LIST[3], COLOURS.LIST[4], COLOURS.LIST[4], COLOURS.LIST[5]),
            fill = c(COLOURS.LIST[1], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[3], COLOURS.LIST[3], COLOURS.LIST[4], COLOURS.LIST[4], COLOURS.LIST[5])
        )),
        colour = "none",
        fill = "none",
    )
save_name <- str_c("training_mse")
create_plot(g, save_name, TEXTWIDTH, 0.2 * HEIGHT)

for (filtered_seed in 1000:1009) {
    g <- ggplot(
        d %>% filter(problem_seed == filtered_seed),
        aes(x = step, y = mean_coeff_abs, colour = as.factor(frequencies))
    ) +
        geom_line(linewidth = LINE.SIZE) +
        geom_line(aes(y = abs_target), linewidth = LINE.SIZE, linetype = "dashed") +
        geom_ribbon(aes(ymin = coeff_lower_bound, ymax = coeff_upper_bound, fill = as.factor(frequencies)), alpha = 0.2, colour = NA) +
        scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
        scale_fill_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
        facet_nested(problem_seed + ansatz ~ noise_category + noise_type,
            labeller = labeller(problem_seed = problem_labeller),
            scale = "free_y"
        ) +
        scale_x_continuous("Step", breaks = seq(0, 1000, 500)) +
        scale_y_continuous("c", limits = c(0, 0.06)) +
        theme_paper() +
        theme(
            legend.margin = margin(b = -4),
            legend.key.height = unit(0.2, "cm"),
            legend.key.width = unit(0.2, "cm")
        ) +
        guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)))
    save_name <- str_c("training_coeffs_seed", filtered_seed)
    create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)
}
