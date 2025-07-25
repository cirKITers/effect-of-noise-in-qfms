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
    filter(qubits < 7) %>%
    mutate(coeffs_abs_mean = ifelse(coeffs_abs_mean < 1e-14, NA, coeffs_abs_mean)) %>%
    mutate(GateError = ifelse(is.na(GateError), 0, GateError)) %>%
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
        coeffs_var_real = mean(coeffs_real_var),
        coeffs_var_imag = mean(coeffs_imag_var),
        coeffs_covar_ri = mean(coeffs_co_var_real_imag)
    ) %>%
    mutate(
        upper_bound = mean_abs + sd_abs,
        lower_bound = mean_abs - sd_abs,
        rel_sd = sd_abs / mean_abs,
        freq2 = 0
    )

d_coeffs_2D <- d_coeffs_2D %>%
    mutate(coeffs_abs_mean = ifelse(coeffs_abs_mean < 1e-14, NA, coeffs_abs_mean)) %>%
    mutate(GateError = ifelse(is.na(GateError), 0, GateError)) %>%
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
    )

stat_coeff <- d_coeffs_1D %>% filter(!is.na(mean_abs))
print(str_c("Max rel sd 1D: ", max(stat_coeff$rel_sd_mean_abs)))
print(str_c("Mean rel sd 1D: ", mean(stat_coeff$rel_sd_mean_abs)))
print(stat_coeff %>% filter(rel_sd_mean_abs == max(stat_coeff$rel_sd_mean_abs)), width = 2000)

stat_coeff <- d_coeffs_2D %>% filter(!is.na(mean_abs))
print(str_c("Max rel sd 2D: ", max(stat_coeff$rel_sd_mean_abs)))
print(str_c("Mean rel sd 2D: ", mean(stat_coeff$rel_sd_mean_abs)))
print(stat_coeff %>% filter(rel_sd_mean_abs == max(stat_coeff$rel_sd_mean_abs)), width = 2000)

d_coeffs <- rbind(d_coeffs_1D, d_coeffs_2D)

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
    distinct(noise_type, noise_value, ansatz, qubits, n_input_feat, freq1, freq2, .keep_all = TRUE) %>%
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
        noise_value = round(noise_value, digits = 3)
    )

d_coeffs$noise_category <- factor(d_coeffs$noise_category, levels = c("","Decoherent Gate", "SPAM", "Damping", "Coh."))
d_coeffs$noise_type <- factor(d_coeffs$noise_type,
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

d_coeffs$ansatz <- factor(d_coeffs$ansatz,
    levels = c("Strongly_Entangling", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "HEA", "Circuit 15", "Circuit 19")
)

d_coeffs_selection <- d_coeffs %>%
    filter(noise_type %in% c("DP", "AD", "CGE"))

d_coeffs_ns <- d_coeffs %>%
    filter(noise_value == 0 & !is.na(mean_abs)) %>%
    group_by(ansatz, qubits, n_input_feat) %>%
    summarise(max_freq1 = max(freq1), max_freq2 = max(freq2))

d_coeffs_selection <- d_coeffs_selection %>%
    merge(d_coeffs_ns, by = c("ansatz", "qubits", "n_input_feat")) %>%
    filter(freq1 == max_freq1 & freq2 == max_freq2 | freq1 == 0 & freq2 == 0) %>%
    mutate(coeff_type = ifelse(freq1 == 0, ifelse(use_tikz, "$0$", "0"), ifelse(use_tikz,"$\\boldsymbol{\\omega}_\\text{max}$", "max")))

d_coeffs_selection$coeff_type <- factor(d_coeffs_selection$coeff_type, levels = c(ifelse(use_tikz, "$0$", "0"), ifelse(use_tikz,"$\\boldsymbol{\\omega}_\\text{max}$", "max")))

g <- ggplot(
    d_coeffs_selection,
    aes(x = noise_value, y = mean_abs, colour = as.factor(qubits), shape = coeff_type, linetype = coeff_type)
) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
    scale_linetype_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", ""), values = c("solid", "11")) +
    scale_shape_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", ""), values = c(4, 17)) +
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
        labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)
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
            ansatz == "SEA" & n_input_feat == 1 & coeff_type == ifelse(use_tikz, "$0$", "0") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{\\omega}})$ [log]", "|c| Mean [log]"),
                breaks = scales::trans_breaks("log10", function(x) 10^(-3:-1)),
                labels = trans_format("log10", math_format(10^.x)),
                trans = "log10",
                limits = c(1e-3, 15e-2)
            ),
            ansatz != "SEA" & coeff_type == ifelse(use_tikz, "$0$", "0") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{\\omega}})$ [log]", "|c| Mean [log]"),
                breaks = scales::trans_breaks("log10", function(x) 10^(-3:-1)),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(1e-3, 15e-2),
                trans = "log10",
                guide = "none"
            ),
            ansatz == "SEA" & n_input_feat != 1 & coeff_type == ifelse(use_tikz, "$0$", "0") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{\\omega}})$ [log]", "|c| Mean [log]"),
                breaks = scales::trans_breaks("log10", function(x) 10^(-3:-1)),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(1e-3, 15e-2),
                trans = "log10",
                guide = "none"
            ),
            ansatz == "SEA" & n_input_feat == 1 & coeff_type == ifelse(use_tikz,"$\\boldsymbol{\\omega}_\\text{max}$", "max") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{\\omega}})$ [log]", "|c| Mean [log]"),
                breaks = c(1e-8, 1e-6, 1e-4, 1e-2),
                labels = trans_format("log10", math_format(10^.x)),
                trans = "log10",
                limits = c(5e-8, 5e-2)
            ),
            ansatz != "SEA" & coeff_type == ifelse(use_tikz,"$\\boldsymbol{\\omega}_\\text{max}$", "max") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{\\omega}})$ [log]", "|c| Mean [log]"),
                breaks = c(1e-8, 1e-6, 1e-4, 1e-2),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(5e-8, 5e-2),
                trans = "log10",
                guide = "none"
            ),
            ansatz == "SEA" & n_input_feat != 1 & coeff_type == ifelse(use_tikz,"$\\boldsymbol{\\omega}_\\text{max}$", "max") ~ scale_y_continuous(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{\\omega}})$ [log]", "|c| Mean [log]"),
                breaks = c(1e-8, 1e-6, 1e-4, 1e-2),
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(5e-8, 5e-2),
                trans = "log10",
                guide = "none"
            )
        )
    )
save_name <- str_c("coeff_abs_mean")
create_plot(g, save_name, COLWIDTH, 0.7 * HEIGHT)
print(warnings())

g <- ggplot(
    d_coeffs_selection,
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
    ) +
    scale_linetype_manual("", values = c("solid", "11")) +
    scale_shape_manual("", values = c(4, 17)) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
    scale_y_continuous(ifelse(use_tikz, "$\\sigma_c({\\boldsymbol{\\omega}})$", "|c| Relative Standard Deviation"), ) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1), shape = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE))) +
    theme(
        legend.margin = margin(b = -4)
    )
save_name <- str_c("coeff_abs_sd")
create_plot(g, save_name, COLWIDTH, 0.7 * HEIGHT)

d_coeffs_6q <- d_coeffs %>%
    filter(n_input_feat == 1 & qubits == 6)

g <- ggplot(d_coeffs_6q, aes(x = noise_value, y = mean_abs, colour = as.factor(freq1))) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "Frequency"), values = COLOURS.LIST) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE))) +
    theme(
        legend.margin = margin(b = -4)
    ) +
    scale_y_log10(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{{\\boldsymbol{\\omega}}}})$ [log]", "|c| Mean [log]"),
        breaks = scales::trans_breaks("log10", function(x) 10^x),
        labels = trans_format("log10", math_format(10^.x))
    ) +
    facet_nested(ansatz ~ noise_category + noise_type,
        labeller = labeller(
            freq1 = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    )

save_name <- str_c("coeff_mean_qubits6")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

g <- ggplot(d_coeffs_6q, aes(x = noise_value, y = rel_sd, colour = as.factor(freq1))) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "Frequency"), values = COLOURS.LIST) +
    scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
    theme_paper() +
    guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE))) +
    theme(
        legend.margin = margin(b = -4)
    ) +
    scale_y_log10(ifelse(use_tikz, "$\\sigma_c({\\boldsymbol{\\omega}})$ [log]", "|c| Relative Standard Deviation"), ) +
    facet_nested(ansatz ~ noise_category + noise_type,
        labeller = labeller(
            freq1 = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    )

save_name <- str_c("coeff_sd_qubits6")
create_plot(g, save_name, TEXTWIDTH, 0.35 * HEIGHT)

d_coeffs_6q <- d_coeffs_6q %>%
    filter(noise_value %in% c(0, 0.03))

d_coeffs_6q$noise_type[d_coeffs_6q$noise_value == 0] <- "Noiseless"
d_coeffs_6q$noise_category[d_coeffs_6q$noise_value == 0] <- ""
d_coeffs_6q <- d_coeffs_6q %>% distinct(noise_type, noise_value, ansatz, qubits, freq1, .keep_all = TRUE) %>%
    pivot_longer(c(coeffs_var_real, coeffs_var_imag, coeffs_covar_ri), names_to = "var_type", values_to = "var")

d_coeffs_6q$var_type <- factor(
    d_coeffs_6q$var_type,
    levels = c("coeffs_var_real", "coeffs_var_imag", "coeffs_covar_ri"),
    labels = c(
                "Re",
                "Im",
                "Re/Im"
    )
)

d_coeffs_6q$var[d_coeffs_6q$var < 1e-15] <- 0

d_coeffs_6q$freq1 <- factor(d_coeffs_6q$freq1, levels = c(0,1,2,3,4,5,6, "max"), labels = c("0", "1", "2", "3", "4", "5", "6", "max"))

d_coeffs_6q <- d_coeffs_6q %>%
    merge(d_coeffs_ns, by = c("ansatz", "qubits", "n_input_feat")) %>%
    filter(freq1 == max_freq1 | freq1 == 1 | freq1 == 0) %>%
    mutate(coeff_type = ifelse(freq1 == 0, ifelse(use_tikz, "$0$", "0"), ifelse(freq1 == 1, ifelse(use_tikz, "$1$", 1), ifelse(use_tikz,"$\\boldsymbol{\\omega}_\\text{max}$", "max"))))

d_coeffs_6q$coeff_type <- factor(d_coeffs_6q$coeff_type, levels = c(ifelse(use_tikz, "$0$", "0"), ifelse(use_tikz, "$1$", "1"), ifelse(use_tikz,"$\\boldsymbol{\\omega}_\\text{max}$", "max")))

g <- ggplot(d_coeffs_6q, aes(x = var_type, y = var, colour = noise_category, shape=noise_type)) +
    geom_point(size = 2 * POINT.SIZE, position = position_dodge(width = 0.7)) +
    facet_nested(coeff_type ~ ansatz,
        labeller = labeller(
            coeff_type = frequencies_labeller,
            qubits = qubit_labeller,
        ),
        scale = "free_y"
    ) +
    theme_paper() +
    scale_colour_manual("", values = COLOURS.LIST) +
    scale_shape_manual("", values = c(19, 15, 9, 6, 4, 3, 0, 1, 17)) +
    scale_x_discrete("") +
    scale_y_continuous(
        ifelse(use_tikz, "$\\text{Cov}(\\cdot, \\cdot)$","Cov(-)"),
        breaks = scales::trans_breaks("log10", function(x) 10^(-15:-1)),
        labels = trans_format("log10", math_format(10^.x)),
        trans = "log10",
    ) +
    guides(
        shape = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(size = 3 * POINT.SIZE, colour = c(COLOURS.LIST[1], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[2], COLOURS.LIST[3], COLOURS.LIST[3], COLOURS.LIST[4], COLOURS.LIST[4], COLOURS.LIST[5]))),
        colour = "none",
    ) +
    theme(
        legend.margin = margin(b = -4, t = 0),
        legend.key.height = unit(0.2, "cm"),
        legend.key.width = unit(0.2, "cm"),
    )
save_name <- str_c("coeff_covar_qubits6_sel")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)
