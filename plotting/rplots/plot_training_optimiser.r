#!/usr/bin/env Rscript

# Training with other optimiser settings (second revision, W3): learning rate,
# number of steps and a cosine learning-rate schedule, under depolarising noise
# at 3% (noise level 0 of the same runs is the noiseless reference).
# The runs of the main study (Adam, learning rate 0.01, 1000 steps, constant
# schedule) serve as the reference setting; they are taken from the summary
# files written by plot_training.r, i.e. averaged over its 10 x 10 runs, while
# the other settings are averaged over 5 x 5 runs.

library(tidyverse)
library(ggh4x)
library(tikzDevice)
library(scales)
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

data_path <- "csv_data/training_optimiser.csv"
data_path_summarised <- "csv_data/training_optimiser_summarised_runs.csv"
data_path_summarised_freq <- "csv_data/training_optimiser_summarised_freq.csv"
# reference (default optimiser) from the main study, written by plot_training.r
ref_path_summarised <- "csv_data/training_summarised_runs.csv"
ref_path_summarised_freq <- "csv_data/training_summarised_freq.csv"

DEFAULT.LR <- 0.01
DEFAULT.STEPS <- 1000
DEFAULT.SCHEDULE <- "constant"

# One label per optimiser setting; the default setting of the main study first.
setting_label <- function(learning_rate, steps, lr_schedule) {
    str_c(
        ifelse(use_tikz, "$\\eta$ = ", "lr = "), learning_rate,
        ifelse(lr_schedule == "cosine", " (cosine)", ""),
        ", ", as.integer(steps), " steps"
    )
}
default_label <- setting_label(DEFAULT.LR, DEFAULT.STEPS, DEFAULT.SCHEDULE)

setting_to_factor <- function(setting) {
    levels <- c(default_label, sort(setdiff(unique(setting), default_label), decreasing = TRUE))
    factor(setting, levels = levels)
}

noise_to_factor <- function(noise_type) {
    factor(noise_type, levels = c("Noiseless", "DP"))
}

if (!file.exists(data_path_summarised) || !file.exists(data_path_summarised_freq)) {
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
        distinct(
            learning_rate, steps, lr_schedule, noise_type, noise_value, ansatz, qubits,
            frequencies, step, problem_seed, seed,
            .keep_all = TRUE
        ) %>%
        mutate(
            coeff_diff_squared = (coeffs_real - target_coefficients_real)^2 +
                (coeffs_imag - target_coefficients_imag)^2,
            noise_value = round(noise_value, digits = 3),
            setting = setting_label(learning_rate, steps, lr_schedule),
        )

    d$noise_type <- factor(d$noise_type,
        levels = c("Noiseless", "Depolarizing"),
        labels = c("Noiseless", "DP")
    )
    d$ansatz <- ansatz_to_factor(d$ansatz)

    d_summarised_freq <- d %>%
        group_by(setting, learning_rate, steps, lr_schedule, noise_type, ansatz, qubits, step, frequencies) %>%
        summarise(
            mean_squared_diff = mean(coeff_diff_squared),
            sd_squared_diff = sd(coeff_diff_squared),
            n_runs = n(),
        ) %>%
        mutate(
            dist_lower_bound = mean_squared_diff - sd_squared_diff,
            dist_upper_bound = mean_squared_diff + sd_squared_diff,
        )

    # Scalar metrics are repeated for every frequency in the exported data.
    d_runs <- d %>%
        distinct(setting, noise_type, ansatz, qubits, step, problem_seed, seed, .keep_all = TRUE)

    d_summarised <- d_runs %>%
        group_by(setting, learning_rate, steps, lr_schedule, noise_type, ansatz, qubits, step) %>%
        summarise(
            mean_mse = mean(mse),
            sd_mse = sd(mse),
            n_runs = n(),
        ) %>%
        mutate(
            mse_lower_bound = mean_mse - sd_mse,
            mse_upper_bound = mean_mse + sd_mse,
        )
    print(d_summarised %>% group_by(setting) %>% summarise(max_step = max(step), runs = max(n_runs)))

    write_csv(d_summarised, data_path_summarised)
    write_csv(d_summarised_freq, data_path_summarised_freq)
} else {
    d_summarised <- read_csv(data_path_summarised)
    d_summarised_freq <- read_csv(data_path_summarised_freq)
}

# Reference setting from the main study (default optimiser); only the noise
# types of this study are used.
ref_summarised <- read_csv(ref_path_summarised) %>%
    filter(noise_type %in% c("Noiseless", "DP")) %>%
    mutate(
        setting = default_label,
        learning_rate = DEFAULT.LR, steps = DEFAULT.STEPS, lr_schedule = DEFAULT.SCHEDULE,
    ) %>%
    select(setting, learning_rate, steps, lr_schedule, noise_type, ansatz, qubits, step,
           mean_mse, sd_mse, mse_lower_bound, mse_upper_bound)
ref_summarised_freq <- read_csv(ref_path_summarised_freq) %>%
    filter(noise_type %in% c("Noiseless", "DP")) %>%
    mutate(
        setting = default_label,
        learning_rate = DEFAULT.LR, steps = DEFAULT.STEPS, lr_schedule = DEFAULT.SCHEDULE,
    ) %>%
    select(setting, learning_rate, steps, lr_schedule, noise_type, ansatz, qubits, step, frequencies,
           mean_squared_diff, sd_squared_diff, dist_lower_bound, dist_upper_bound)

d_summarised <- bind_rows(d_summarised, ref_summarised)
d_summarised_freq <- bind_rows(d_summarised_freq, ref_summarised_freq)

for (name in c("d_summarised", "d_summarised_freq")) {
    tmp <- get(name)
    tmp$setting <- setting_to_factor(tmp$setting)
    tmp$noise_type <- noise_to_factor(tmp$noise_type)
    tmp$ansatz <- factor(tmp$ansatz, levels = c("SEA", "HEA", "RYA", "CRA"))
    assign(name, tmp)
}

diff_label <- ifelse(use_tikz, "$\\Delta c_{\\boldsymbol{\\omega}}$", "Diff")
freq_label <- ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w")
scale_fill_setting <- scale_fill_manual(NULL, values = COLOURS.LIST)
scale_colour_setting <- scale_colour_manual(NULL, values = COLOURS.LIST)

# ---------------------------------------------------------------------------
# Final state per setting (last step of the respective setting), in the style
# of training_coeff_dist_final: MSE on the left, squared coefficient error per
# frequency on the right; bars coloured by optimiser setting.
# ---------------------------------------------------------------------------
d_final_diff <- d_summarised_freq %>%
    group_by(setting) %>%
    filter(step == max(step)) %>%
    ungroup() %>%
    mutate(dist_lower_bound = pmax(dist_lower_bound, 0))
d_final_mse <- d_summarised %>%
    group_by(setting) %>%
    filter(step == max(step)) %>%
    ungroup() %>%
    mutate(mse_lower_bound = pmax(mse_lower_bound, 0))

DODGE <- 0.8

g_final_mse <- ggplot(
    d_final_mse,
    aes(x = noise_type, y = mean_mse, fill = setting)
) +
    geom_col(width = DODGE, position = position_dodge(DODGE)) +
    geom_errorbar(aes(ymin = mse_lower_bound, ymax = mse_upper_bound),
        width = 0.4, linewidth = 0.3, position = position_dodge(DODGE)
    ) +
    scale_fill_setting +
    facet_nested(ansatz ~ .) +
    scale_x_discrete(NULL) +
    scale_y_continuous("MSE", breaks = seq(0, 1, 0.01)) +
    theme_paper() +
    theme(
        axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
        # the ansatz strips are shown in the coefficient plot on the right
        strip.text.y = element_blank(),
        strip.background.y = element_blank(),
        plot.margin = margin(0, 0, 0, 0)
    )

g_final_diff <- ggplot(
    d_final_diff,
    aes(x = frequencies, y = mean_squared_diff, fill = setting)
) +
    geom_col(width = DODGE, position = position_dodge(DODGE)) +
    geom_errorbar(aes(ymin = dist_lower_bound, ymax = dist_upper_bound),
        width = 0.4, linewidth = 0.3, position = position_dodge(DODGE)
    ) +
    scale_fill_setting +
    facet_nested(ansatz ~ noise_type) +
    scale_x_continuous(freq_label, breaks = seq(0, 6, 1)) +
    scale_y_continuous(diff_label, breaks = seq(0, 1, 0.002)) +
    theme_paper() +
    theme(
        panel.spacing.x = unit(1.5, "pt"),
        axis.title.x = element_text(vjust = 5),
        plot.margin = margin(0, 0, 0, 0)
    )

g <- (g_final_mse | plot_spacer() | g_final_diff) +
    plot_layout(guides = "collect", widths = c(19, 1, 50)) &
    theme(
        legend.position = "top",
        legend.margin = margin(b = -4),
        legend.key.height = unit(0.4, "cm"),
        legend.key.width = unit(0.4, "cm"),
        plot.margin = margin(0, 0, 0, 0)
    ) &
    guides(fill = guide_legend(nrow = 2, theme = theme(legend.byrow = TRUE)))
save_name <- str_c("training_optimiser_final")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

# ---------------------------------------------------------------------------
# MSE during training per setting, in the style of training_mse.
# ---------------------------------------------------------------------------
g <- ggplot(
    d_summarised %>% mutate(mse_lower_bound = pmax(mse_lower_bound, 0)),
    aes(x = step, y = mean_mse, colour = setting)
) +
    geom_line(linewidth = LINE.SIZE) +
    geom_ribbon(aes(ymin = mse_lower_bound, ymax = mse_upper_bound, fill = setting), alpha = 0.1, colour = NA) +
    scale_colour_setting +
    scale_fill_setting +
    facet_nested(noise_type ~ ansatz) +
    scale_x_continuous("Step", breaks = seq(0, 3000, 1000)) +
    scale_y_continuous("MSE", limits = c(0, 0.065)) +
    theme_paper() +
    guides(
        colour = guide_legend(nrow = 2, theme = theme(legend.byrow = TRUE)),
        fill = "none",
    )
save_name <- str_c("training_optimiser_mse")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)

# ---------------------------------------------------------------------------
# Summary for the text: final MSE and the share of the final squared error at
# the two highest frequencies, per setting, ansatz and noise type.
# ---------------------------------------------------------------------------
omega_max <- max(d_final_diff$frequencies)
d_high <- d_final_diff %>%
    group_by(setting, noise_type, ansatz) %>%
    summarise(
        total_diff = sum(mean_squared_diff * ifelse(frequencies == 0, 1, 2)),
        high_diff = sum(mean_squared_diff * ifelse(frequencies == 0, 1, 2) * (frequencies >= omega_max - 1)),
    ) %>%
    mutate(high_share = high_diff / total_diff)
print(d_final_mse %>% select(setting, noise_type, ansatz, mean_mse, sd_mse), n = 100)
print(d_high, n = 100)
