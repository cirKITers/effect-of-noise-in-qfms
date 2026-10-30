#!/usr/bin/env Rscript

library(tidyverse)
library(ggh4x)
library(tikzDevice)
library(scales)
library(ggrastr)
library(patchwork)
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
data_path_processed <- "csv_data/training_processed.csv"
data_path_summarised <- "csv_data/training_summarised_runs.csv"
data_path_summarised_freq <- "csv_data/training_summarised_freq.csv"
data_path_summarised_seed <- "csv_data/training_summarised_seed_runs.csv"

# training objective: MSE on the training inputs ("mse") or the squared complex
# coefficient error ("coeff"), see training.loss in conf/base/parameters.yml
loss_to_factor <- function(loss) factor(loss, levels = c("mse", "coeff"))

if (!file.exists(data_path_summarised) || !file.exists(data_path_summarised_freq) || !file.exists(data_path_summarised_seed) || !file.exists(data_path_processed)) {
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
        distinct(loss, noise_type, noise_value, ansatz, qubits, frequencies, step, problem_seed, seed, .keep_all = TRUE) %>%
        mutate(
            coeff_diff = sqrt((coeffs_real - target_coefficients_real)^2 + (coeffs_imag - target_coefficients_imag)^2),
            coeff_diff_squared = coeff_diff^2,
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

    d$ansatz <- ansatz_to_factor(d$ansatz)
    d$loss <- loss_to_factor(d$loss)

    d_summarised_freq <- d %>%
        group_by(loss, noise_category, noise_type, ansatz, qubits, step, frequencies) %>%
        summarise(
            mean_abs_dist = mean(coeff_abs_dist),
            sd_abs_dist = sd(coeff_abs_dist),
            mean_diff = mean(coeff_diff),
            sd_diff = sd(coeff_diff),
            mean_squared_diff = mean(coeff_diff_squared),
            sd_squared_diff = sd(coeff_diff_squared),
        ) %>%
        mutate(
            # squared complex error, including phase differences
            dist_lower_bound = mean_squared_diff - sd_squared_diff,
            dist_upper_bound = mean_squared_diff + sd_squared_diff,
        )


    # Scalar metrics are repeated for every frequency in the exported data.
    d_runs <- d %>%
        distinct(noise_type, noise_value, ansatz, qubits, step, problem_seed, seed, .keep_all = TRUE)

    d_summarised <- d_runs %>%
        group_by(loss, noise_category, noise_type, ansatz, qubits, step) %>%
        summarise(
            mean_mse = mean(mse),
            sd_mse = sd(mse),
            mean_dist = mean(coeff_dist),
            sd_dist = sd(coeff_dist),
            mean_ent = mean(entanglement),
            sd_ent = sd(entanglement),
        ) %>%
        mutate(
            mse_lower_bound = mean_mse - sd_mse,
            mse_upper_bound = mean_mse + sd_mse,
            dist_lower_bound = mean_dist - sd_dist,
            dist_upper_bound = mean_dist + sd_dist,
            ent_lower_bound = mean_ent - sd_ent,
            ent_upper_bound = mean_ent + sd_ent,
        )
    print(d_summarised)

    # MSE per problem seed (mean/sd over the initialisation seeds)
    d_summarised_seed <- d_runs %>%
        group_by(loss, noise_category, noise_type, ansatz, qubits, step, problem_seed) %>%
        summarise(
            mean_mse = mean(mse),
            sd_mse = sd(mse),
        ) %>%
        mutate(
            mse_lower_bound = mean_mse - sd_mse,
            mse_upper_bound = mean_mse + sd_mse,
        )

    d <- d %>%
        group_by(loss, noise_category, noise_type, noise_value, ansatz, qubits, frequencies, step, problem_seed) %>%
        summarise(
            abs_target = mean(abs_target),
            mean_coeff_abs = mean(coeff_abs),
            sd_coeff_abs = sd(coeff_abs),
            mean_abs_dist = mean(coeff_abs_dist),
            sd_abs_dist = sd(coeff_abs_dist),
            mean_diff = mean(coeff_diff),
            sd_diff = sd(coeff_diff),
            mean_squared_diff = mean(coeff_diff_squared),
            sd_squared_diff = sd(coeff_diff_squared),
        ) %>%
        mutate(
            coeff_lower_bound = mean_coeff_abs - sd_coeff_abs,
            coeff_upper_bound = mean_coeff_abs + sd_coeff_abs,
            dist_lower_bound = mean_squared_diff - sd_squared_diff,
            dist_upper_bound = mean_squared_diff + sd_squared_diff,
        )
    print(colnames(d))

    write_csv(d, data_path_processed)
    write_csv(d_summarised, data_path_summarised)
    write_csv(d_summarised_freq, data_path_summarised_freq)
    write_csv(d_summarised_seed, data_path_summarised_seed)
} else {
    d <- read_csv(data_path_processed)
    d_summarised <- read_csv(data_path_summarised)
    d_summarised_freq <- read_csv(data_path_summarised_freq)
    d_summarised_seed <- read_csv(data_path_summarised_seed)

    d$noise_category[is.na(d$noise_category)] <- ""
    d$noise_category <- factor(d$noise_category, levels = c("", "Decoherent Gate", "SPAM", "Damping", "Coh."))
    d$noise_type <- factor(d$noise_type,
        levels = c(
            "Noiseless", "BF", "PF", "DP",
            "AD", "PD",
            "SP", "ME",
            "CGE"
        ),
    )
    d$ansatz <- factor(d$ansatz,
        levels = c("SEA", "HEA", "RYA", "CRA")
    )
    d$loss <- loss_to_factor(d$loss)
    d_summarised$noise_category[is.na(d_summarised$noise_category)] <- ""
    d_summarised$noise_category <- factor(d_summarised$noise_category, levels = c("", "Decoherent Gate", "SPAM", "Damping", "Coh."))
    d_summarised$noise_type <- factor(d_summarised$noise_type,
        levels = c(
            "Noiseless", "BF", "PF", "DP",
            "AD", "PD",
            "SP", "ME",
            "CGE"
        ),
    )
    d_summarised$ansatz <- factor(d_summarised$ansatz,
        levels = c("SEA", "HEA", "RYA", "CRA")
    )
    d_summarised$loss <- loss_to_factor(d_summarised$loss)
    d_summarised_freq$noise_category[is.na(d_summarised_freq$noise_category)] <- ""
    d_summarised_freq$noise_category <- factor(d_summarised_freq$noise_category, levels = c("", "Decoherent Gate", "SPAM", "Damping", "Coh."))
    d_summarised_freq$noise_type <- factor(d_summarised_freq$noise_type,
        levels = c(
            "Noiseless", "BF", "PF", "DP",
            "AD", "PD",
            "SP", "ME",
            "CGE"
        ),
    )
    d_summarised_freq$ansatz <- factor(d_summarised_freq$ansatz,
        levels = c("SEA", "HEA", "RYA", "CRA")
    )
    d_summarised_freq$loss <- loss_to_factor(d_summarised_freq$loss)
    d_summarised_seed$noise_category[is.na(d_summarised_seed$noise_category)] <- ""
    d_summarised_seed$noise_category <- factor(d_summarised_seed$noise_category, levels = c("", "Decoherent Gate", "SPAM", "Damping", "Coh."))
    d_summarised_seed$noise_type <- factor(d_summarised_seed$noise_type,
        levels = c(
            "Noiseless", "BF", "PF", "DP",
            "AD", "PD",
            "SP", "ME",
            "CGE"
        ),
    )
    d_summarised_seed$ansatz <- factor(d_summarised_seed$ansatz,
        levels = c("SEA", "HEA", "RYA", "CRA")
    )
    d_summarised_seed$loss <- loss_to_factor(d_summarised_seed$loss)
}

diff_label <- ifelse(use_tikz, "$\\Delta c_{\\boldsymbol{\\omega}}$", "Diff")

g <- ggplot(
    d_summarised_freq,
    aes(x = step, y = mean_squared_diff, colour = as.factor(frequencies))
) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = dist_lower_bound, ymax = dist_upper_bound, fill = as.factor(frequencies)), alpha = 0.2, colour = NA) +
    scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
    scale_fill_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type) +
    scale_x_continuous("Step", breaks = seq(0, 1000, 400)) +
    scale_y_continuous(diff_label) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)))
save_name <- str_c("training_coeff_dist")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

# Bar plots of the state after the last training step, joined with patchwork:
# on the left the final MSE per noise type (noise types on the x axis), on the
# right the final coefficient difference per frequency with the noise types as
# columns; ansaetze in the rows, bars coloured by noise category in both plots.
freq_label <- ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w")
freq_levels <- as.character(sort(unique(d_summarised_freq$frequencies)))
final_step <- max(d_summarised_freq$step)
blank_noiseless <- function(x) ifelse(x == "Noiseless", "", x)
y_expand <- expansion(mult = c(0, 0.05))
d_final_diff <- d_summarised_freq %>%
    filter(step == final_step) %>%
    ungroup() %>%
    mutate(
        # the quantities are non-negative, so the error bars are not drawn below zero
        dist_lower_bound = pmax(dist_lower_bound, 0),
    )
d_final_mse <- d_summarised %>%
    filter(step == final_step) %>%
    ungroup() %>%
    mutate(
        mse_lower_bound = pmax(mse_lower_bound, 0),
    )
mse_max <- max(d_final_mse$mse_upper_bound)
diff_max <- max(d_final_diff$dist_upper_bound)

# noise category colours as in the training_mse plot
category_breaks <- c("", "Decoherent Gate", "SPAM", "Damping", "Coh.")
scale_fill_category <- scale_fill_manual(
    NULL,
    values = COLOURS.LIST, breaks = category_breaks,
    # the noiseless case (empty category label) needs no legend entry
    limits = category_breaks, labels = c("Noiseless", category_breaks[-1])
)

g_final_mse <- ggplot(
    d_final_mse,
    aes(x = noise_type, y = mean_mse, fill = noise_category)
) +
    geom_col(width = 0.8) +
    geom_errorbar(aes(ymin = mse_lower_bound, ymax = mse_upper_bound), width = 0.5, linewidth = 0.3) +
    scale_fill_category +
    facet_nested(ansatz ~ .) +
    scale_x_discrete(NULL, labels=blank_noiseless) +
    scale_y_continuous("MSE", breaks=seq(0,1,0.01)) +
    theme_paper() +
    theme(
        axis.text.x = element_text(, angle = 90, hjust = 1, vjust = 0.5),
        # the ansatz strips are shown in the coefficient plot on the right
        strip.text.y = element_blank(),
        strip.background.y = element_blank(),
        plot.margin = margin(0, 0, 0, 0)
    )

g_final_diff <- ggplot(
    d_final_diff,
    aes(x = frequencies, y = mean_squared_diff, fill = noise_category)
) +
    geom_col(width = 0.8) +
    geom_errorbar(aes(ymin = dist_lower_bound, ymax = dist_upper_bound), width = 0.5, linewidth = 0.3) +
    scale_fill_category +
    facet_nested(ansatz ~ noise_type, labeller = labeller(noise_type = blank_noiseless)) +
    scale_x_continuous(freq_label) +
    scale_y_continuous(diff_label) +
    theme_paper() +
    theme(
        panel.spacing.x = unit(1.5, "pt"),
        axis.title.x = element_text(vjust=5),
        plot.margin = margin(0, 0, 0, 0)
    )

# MSE plot left, coefficient difference plot right, separated by a small spacer;
# one shared noise category legend on top
g <- (g_final_mse | plot_spacer() | g_final_diff) +
    plot_layout(guides = "collect", widths = c(19, 1, 50)) &
    theme(
        legend.position = "top",
        legend.margin = margin(b = -4),
        legend.key.height = unit(0.4, "cm"),
        legend.key.width = unit(0.4, "cm"),
        plot.margin = margin(0, 0, 0, 0)
    ) &
    guides(fill = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)))
save_name <- str_c("training_coeff_dist_final")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

g <- ggplot(
    d_summarised,
    aes(x = step, y = mean_mse, colour = noise_category, linetype = noise_type)
) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = mse_lower_bound, ymax = mse_upper_bound, fill = noise_category), alpha = 0.1, colour = NA) +
    scale_colour_manual("", values = COLOURS.LIST, breaks = c("", "Decoherent Gate", "SPAM", "Damping", "Coh.")) +
    scale_fill_manual("", values = COLOURS.LIST, breaks = c("", "Decoherent Gate", "SPAM", "Damping", "Coh.")) +
    scale_linetype_manual("", values = c(1, 1, 2, 111, 1, 2, 1, 2, 1)) +
    facet_nested(. ~ ansatz) +
    scale_x_continuous("Step", breaks = seq(0, 1000, 400)) +
    scale_y_continuous("MSE") +
    theme_paper() +
    guides(
        linetype = guide_legend(nrow = 2, theme = theme(legend.byrow = TRUE), override.aes = list(
            colour = c(COLOURS.LIST[1], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[3], COLOURS.LIST[3], COLOURS.LIST[4], COLOURS.LIST[4], COLOURS.LIST[5]),
            fill = c(COLOURS.LIST[1], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[3], COLOURS.LIST[3], COLOURS.LIST[4], COLOURS.LIST[4], COLOURS.LIST[5])
        )),
        colour = "none",
        fill = "none",
    )
save_name <- str_c("training_mse")
create_plot(g, save_name, 0.6 * TEXTWIDTH, 0.25 * HEIGHT)

g <- ggplot(
    d_summarised,
    aes(x = step, y = mean_ent), colour = "black"
) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = ent_lower_bound, ymax = ent_upper_bound), fill = "black", alpha = 0.2, colour = NA) +
    facet_nested(ansatz ~ noise_category + noise_type) +
    scale_x_continuous("Step", breaks = seq(0, 1000, 400)) +
    scale_y_continuous("Entangling Capability") +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)))
save_name <- str_c("training_ent")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)


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
            scale = "free_y",
        ) +
        scale_x_continuous("Step", breaks = seq(0, 1000, 400)) +
        scale_y_continuous(ifelse(use_tikz, "$\\lvert c_{\\boldsymbol{\\omega}} \\rvert$", "c")) +
        theme_paper() +
        theme(
            legend.margin = margin(b = -4),
            legend.key.height = unit(0.4, "cm"),
            legend.key.width = unit(0.4, "cm")
        ) +
        guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)))
    save_name <- str_c("training_coeffs_seed", filtered_seed)
    create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

    # Joined plot of the noiseless training for this problem seed:
    # top row MSE (mean +- sd over the initialisation seeds), bottom row
    # the noiseless squared coefficient errors, one column per ansatz.
    d_mse_noiseless <- d_summarised_seed %>%
        filter(problem_seed == filtered_seed & noise_type == "Noiseless")
    d_coeffs_noiseless <- d %>%
        filter(problem_seed == filtered_seed & noise_type == "Noiseless")
    if (nrow(d_mse_noiseless) == 0 || nrow(d_coeffs_noiseless) == 0) {
        next
    }

    g_mse <- ggplot(
        d_mse_noiseless,
        aes(x = step, y = mean_mse)
    ) +
        geom_line(linewidth = LINE.SIZE, colour = "#666666") +
        geom_ribbon(aes(ymin = mse_lower_bound, ymax = mse_upper_bound), fill = "#666666", alpha = 0.2, colour = NA) +
        facet_nested(. ~ ansatz,
            labeller = labeller(problem_seed = problem_labeller),
        ) +
        scale_x_continuous("Step", breaks = seq(0, 1000, 400)) +
        scale_y_continuous("MSE", limits = c(-0.005, 0.06)) +
        theme_paper() +
        theme(
            axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank()
        )

    g_coeffs <- ggplot(
        d_coeffs_noiseless,
        aes(x = step, y = mean_squared_diff, colour = as.factor(frequencies))
    ) +
        geom_line(linewidth = LINE.SIZE) +
        geom_ribbon(aes(ymin = dist_lower_bound, ymax = dist_upper_bound, fill = as.factor(frequencies)), alpha = 0.2, colour = NA) +
        scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
        scale_fill_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), values = COLOURS.LIST) +
        facet_nested(. ~ ansatz) +
        scale_x_continuous("Step", breaks = seq(0, 1000, 400)) +
        scale_y_continuous(diff_label) +
        theme_paper() +
        theme(
            # the ansatz strips are already shown in the MSE row
            strip.text.x = element_blank(),
            strip.background.x = element_blank()
        ) +
        guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)))

    g <- (g_mse / plot_spacer() / g_coeffs) +
        plot_layout(guides = "collect", heights = c(22,1,29)) &
        theme(
            legend.position = "top",
            legend.margin = margin(b = -4),
            legend.key.height = unit(0.4, "cm"),
            legend.key.width = unit(0.4, "cm"),
            plot.margin = margin(0,0,0,0)
        )
    save_name <- str_c("training_noiseless_seed", filtered_seed)
    create_plot(g, save_name, 0.6*TEXTWIDTH, 0.25 * HEIGHT)
}
