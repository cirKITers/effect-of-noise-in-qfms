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

coeffs_path <- "csv_data/coeffs_full.csv"

d_coeffs_full <- read_csv(coeffs_path)

index_labeller <- function(layer) {
    paste0("i = ", layer)
}

d_coeffs_full$ansatz <- factor(d_coeffs_full$ansatz, labels = c("Strongly_Entangling" = "SEA", "Hardware_Efficient" = "HEA", "Circuit_15" = "Circuit 15", "Circuit_19" = "Circuit 19"))
d_coeffs_full$frequencies <- as.factor(d_coeffs_full$frequencies)

d_coeffs_full <- d_coeffs_full %>%
    mutate(
        coeffs_abs = sqrt(coeffs_full_real^2 + coeffs_full_imag^2),
        coeffs_abs_real = abs(coeffs_full_real),
        coeffs_abs_imag = abs(coeffs_full_imag)
    ) %>%
    # Filter zero coefficients
    filter(coeffs_abs > 1e-14)

for (n_qubits in list(3, 4, 5, 6, 7)) {
    d_coeffs <- d_coeffs_full %>% filter(qubits == n_qubits)
    d_coeffs <- d_coeffs %>%
        pivot_longer(
            c(
                BitFlip, PhaseFlip, Depolarizing,
                AmplitudeDamping, PhaseDamping,
                StatePreparation, Measurement, GateError
            ),
            names_to = "noise_type", values_to = "noise_value"
        ) %>%
        filter(!is.na(noise_value))

    d_coeffs <- d_coeffs %>%
        distinct(noise_type, noise_value, ansatz, qubits, frequencies, seed, sample_idx, .keep_all = TRUE) %>%
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

    d_coeffs_summarised <- d_coeffs %>%
        group_by(noise_type, noise_value, noise_category, ansatz, qubits, frequencies) %>%
        summarise(
            mean_abs = mean(coeffs_abs),
            sd_abs = sd(coeffs_abs),
            mean_real = mean(coeffs_abs_real),
            sd_real = sd(coeffs_abs_real),
            max_real = max(coeffs_abs_real),
            min_real = min(coeffs_abs_real),
            mean_imag = mean(coeffs_abs_imag),
            sd_imag = sd(coeffs_abs_imag),
            max_imag = max(coeffs_abs_imag),
            min_imag = min(coeffs_abs_imag),
        ) %>%
        mutate(
            upper_bound_real = mean_real + sd_real,
            upper_bound_imag = mean_imag + sd_imag,
            lower_bound_real = mean_real - sd_real,
            lower_bound_imag = mean_imag - sd_imag,
        )

    d_coeffs_summarised$noise_category <- factor(d_coeffs_summarised$noise_category, levels = c("Decoherent Gate", "Coherent", "SPAM", "Damping"))
    d_coeffs_summarised$noise_type <- factor(d_coeffs_summarised$noise_type,
        levels = c(
            "BitFlip", "PhaseFlip", "Depolarizing",
            "AmplitudeDamping", "PhaseDamping",
            "StatePreparation", "Measurement",
            "GateError"
        ),
        labels = c(
            "Bit Flip", "Phase Flip", "Depolarising",
            "Amplitude Damping", "Phase Damping",
            "State Preparation", "Measurement",
            "Gate Error"
        )
    )


    single_qubit_freq_stuff <- function(g) {
        g <- g +
            geom_point(size = POINT.SIZE) +
            geom_line(linewidth = LINE.SIZE) +
            scale_colour_manual("Frequency", values = COLOURS.LIST) +
            scale_fill_manual("Frequency", values = COLOURS.LIST) +
            facet_nested(ansatz ~ noise_category + noise_type,
                labeller = labeller(
                    frequencies = frequencies_labeller,
                    qubits = qubit_labeller,
                ),
            ) +
            scale_x_continuous("Noise Probability", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
            theme_paper() +
            guides(colour = guide_legend(nrow = 1)) +
            theme(
                legend.margin = margin(b = -1)
            )
        return(g)
    }

    g <- ggplot(
        d_coeffs_summarised,
        aes(x = noise_value, y = mean_abs, colour = frequencies)
    ) +
        scale_y_log10(ifelse(use_tikz, "$\\bar{\\lvert{c}_\\omega\\rvert}$ [log]", "|c| Mean [log]"),
            breaks = scales::trans_breaks("log10", function(x) 10^x),
            labels = trans_format("log10", math_format(10^.x))
        )
    g <- single_qubit_freq_stuff(g)
    save_name <- str_c("coeff_mean_qubits", n_qubits)
    create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)

    g <- ggplot(
        d_coeffs_summarised,
        aes(x = noise_value, y = sd_abs, colour = frequencies)
    ) +
        scale_y_log10(ifelse(use_tikz, "$\\sigma(\\lvert{c}_\\omega\\rvert)$ [log]", "|c| Standard Deviation [log]"),
            breaks = scales::trans_breaks("log10", function(x) 10^x),
            labels = trans_format("log10", math_format(10^.x))
        )
    g <- single_qubit_freq_stuff(g)
    save_name <- str_c("coeff_sd_qubits", n_qubits)
    create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)



    d_coeffs_ansatz <- d_coeffs %>%
        filter(noise_value %in% c(0, 0.03))
    d_coeffs_ansatz$noise_type[d_coeffs_ansatz$noise_value == 0] <- "Noiseless"
    d_coeffs_ansatz$noise_category[d_coeffs_ansatz$noise_value == 0] <- ""
    d_coeffs_ansatz <- d_coeffs_ansatz %>% distinct(noise_type, noise_value, ansatz, qubits, frequencies, seed, sample_idx, .keep_all = TRUE)
    d_coeffs_ansatz$noise_type <- factor(d_coeffs_ansatz$noise_type,
        levels = c(
            "Noiseless", "BitFlip", "PhaseFlip", "Depolarizing",
            "AmplitudeDamping", "PhaseDamping",
            "StatePreparation", "Measurement",
            "GateError"
        ),
        labels = c(
            "Noiseless", "Bit Flip", "Phase Flip", "Depolarising",
            "Amplitude Damping", "Phase Damping",
            "State Preparation", "Measurement",
            "Gate Error"
        ),
    )
    d_coeffs_ansatz$noise_category <- factor(d_coeffs_ansatz$noise_category, levels = c("", "Decoherent Gate", "Coherent", "SPAM", "Damping"))

    g <- ggplot(d_coeffs_ansatz, aes(x = coeffs_full_real, y = coeffs_full_imag, colour = frequencies)) +
        geom_point_rast(size = POINT.SIZE, alpha = 0.7, shape = 16, raster.dpi = 600) +
        facet_nested(ansatz ~ noise_category + noise_type,
            labeller = labeller(
                frequencies = frequencies_labeller,
                qubits = qubit_labeller,
            ),
        ) +
        scale_colour_manual("Frequency", values = COLOURS.LIST) +
        theme_paper() +
        scale_x_continuous("Real Part", limits = c(-0.3, 0.3)) +
        scale_y_continuous("Imaginary Part", limits = c(-0.3, 0.3)) +
        guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)), override.aes = list(alpha = 1, size = 2*POINT.SIZE)) +
        theme(
            legend.margin = margin(b = -3, t = 0)
        )
    save_name <- str_c("coeff_real_imag_qubits", n_qubits)
    create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)
}
