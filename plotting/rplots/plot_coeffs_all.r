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
        max_freq = max(freq1),
        coeffs_var_real = mean(coeffs_real_var),
        coeffs_var_imag = mean(coeffs_imag_var),
        coeffs_covar_ri = mean(coeffs_co_var_real_imag)
    ) %>%
    mutate(
        upper_bound = mean_abs + sd_abs,
        lower_bound = mean_abs - sd_abs,
        rel_sd = sd_abs / mean_abs,
    )

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

d_coeffs_ns <- d_coeffs %>%
    filter(noise_value == 0 & !is.na(mean_abs)) %>%
    group_by(ansatz, qubits, n_input_feat) %>%
    summarise(max_freq1 = max(freq1), max_freq2 = max(freq2))

for (n_q in 3:6) {
    d_coeffs_q <- d_coeffs %>%
        filter(n_input_feat == 1 & qubits == n_q)

    g <- ggplot(d_coeffs_q, aes(x = noise_value, y = mean_abs, colour = as.factor(freq1))) +
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

    save_name <- str_c("coeff_mean_qubits", n_q)
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)

    g <- ggplot(d_coeffs_q, aes(x = noise_value, y = rel_sd, colour = as.factor(freq1))) +
        geom_point(size = POINT.SIZE) +
        geom_line(linewidth = LINE.SIZE) +
        scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "Frequency"), values = COLOURS.LIST) +
        scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
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

    save_name <- str_c("coeff_sd_qubits", n_q)
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)

    d_coeffs_q <- d_coeffs_q %>%
        filter(noise_value %in% c(0, 0.03))

    d_coeffs_q$noise_type[d_coeffs_q$noise_value == 0] <- "Noiseless"
    d_coeffs_q$noise_category[d_coeffs_q$noise_value == 0] <- ""
    d_coeffs_q <- d_coeffs_q %>% distinct(noise_type, noise_value, ansatz, qubits, freq1, .keep_all = TRUE) %>%
        pivot_longer(c(coeffs_var_real, coeffs_var_imag, coeffs_covar_ri), names_to = "var_type", values_to = "var")

    d_coeffs_q$var_type <- factor(
        d_coeffs_q$var_type,
        levels = c("coeffs_var_real", "coeffs_var_imag", "coeffs_covar_ri"),
        labels = c(
                    "Re",
                    "Im",
                    "Re/Im"
        )
    )

    d_coeffs_q$var[d_coeffs_q$var < 1e-15] <- 0

    g <- ggplot(d_coeffs_q, aes(x = var_type, y = var, colour = noise_category, shape=noise_type)) +
        geom_point(size = 2 * POINT.SIZE, position = position_dodge(width = 0.7)) +
        facet_nested(freq1 ~ ansatz,
            labeller = labeller(
                freq1 = frequencies_labeller,
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
    save_name <- str_c("coeff_covar_qubits", n_q)
    create_plot(g, save_name, COLWIDTH, n_q * 0.1 * HEIGHT)

    d_coeffs_q <- d_coeffs %>%
        filter(n_input_feat == 2 & qubits == n_q & freq1 >= 0 & freq2 >= 0)

    g <- ggplot(d_coeffs_q, aes(x = noise_value, y = mean_abs, colour = as.factor(freq2))) +
        geom_point(size = POINT.SIZE) +
        geom_line(linewidth = LINE.SIZE) +
        scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}^{(2)}$", "Frequency 2"), values = COLOURS.LIST) +
        scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
        theme_paper() +
        guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE))) +
        theme(
            legend.margin = margin(b = -4)
        ) +
        scale_y_log10(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{{\\boldsymbol{\\omega}}}})$ [log]", "|c| Mean [log]"),
            breaks = scales::trans_breaks("log10", function(x) 10^(-15:-1)),
            labels = trans_format("log10", math_format(10^.x))
        ) +
        facet_nested(ansatz + freq1 ~ noise_category + noise_type,
            labeller = labeller(
                freq1 = freq1_labeller,
                qubits = qubit_labeller,
            ),
        )

    save_name <- str_c("coeff_mean_qubits", n_q, "_2D")
    create_plot(g, save_name, COLWIDTH, (0.2 * n_q + 0.1) * HEIGHT)

    g <- ggplot(d_coeffs_q, aes(x = noise_value, y = rel_sd, colour = as.factor(freq2))) +
        geom_point(size = POINT.SIZE) +
        geom_line(linewidth = LINE.SIZE) +
        scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}^{(2)}$", "Frequency 2"), values = COLOURS.LIST) +
        scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
        theme_paper() +
        guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE))) +
        theme(
            legend.margin = margin(b = -4)
        ) +
        scale_y_log10(ifelse(use_tikz, "$\\sigma_c({\\boldsymbol{\\omega}})$ [log]", "|c| Relative Standard Deviation"), ) +
        facet_nested(ansatz + freq1 ~ noise_category + noise_type,
            labeller = labeller(
                freq1 = freq1_labeller,
                qubits = qubit_labeller,
            ),
        )

    save_name <- str_c("coeff_sd_qubits", n_q, "_2D")
    create_plot(g, save_name, COLWIDTH, (0.2 * n_q + 0.1) * HEIGHT)

    d_coeffs_q <- d_coeffs_q %>%
        filter(noise_value %in% c(0, 0.03))

    d_coeffs_q$noise_type[d_coeffs_q$noise_value == 0] <- "Noiseless"
    d_coeffs_q$noise_category[d_coeffs_q$noise_value == 0] <- ""
    d_coeffs_q <- d_coeffs_q %>% distinct(noise_type, noise_value, ansatz, qubits, freq1, freq2, .keep_all = TRUE) %>%
        pivot_longer(c(coeffs_var_real, coeffs_var_imag, coeffs_covar_ri), names_to = "var_type", values_to = "var")

    d_coeffs_q$var_type <- factor(
        d_coeffs_q$var_type,
        levels = c("coeffs_var_real", "coeffs_var_imag", "coeffs_covar_ri"),
        labels = c(
                    "Re",
                    "Im",
                    "Re/Im"
        )
    )

    d_coeffs_q$var[d_coeffs_q$var < 1e-15] <- 0

    g <- ggplot(d_coeffs_q, aes(x = var_type, y = var, colour = noise_category, shape=noise_type)) +
        geom_point(size = 2 * POINT.SIZE, position = position_dodge(width = 0.7)) +
        facet_nested(freq1 + freq2 ~ ansatz,
            labeller = labeller(
                freq1 = freq1_labeller,
                freq2 = freq2_labeller,
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
    save_name <- str_c("coeff_covar_qubits", n_q, "_2D")
    create_plot(g, save_name, COLWIDTH, (n_q * n_q * 0.1) * HEIGHT)
}
