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

coeffs_path <- "csv_data/coeffs_full_dims1.csv"

d_coeffs_full <- read_csv(coeffs_path)
d_coeffs_full <- d_coeffs_full %>% filter(qubits < 7)

index_labeller <- function(layer) {
    paste0("i = ", layer)
}

d_coeffs_full$ansatz <- factor(d_coeffs_full$ansatz,
    levels = c("Strongly_Entangling", "Strongly_Entangling_Plus", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "SEA+", "HEA", "Circuit 15", "Circuit 19")
)
d_coeffs_full$freq1 <- as.factor(d_coeffs_full$freq1)

d_coeffs_full <- d_coeffs_full %>%
    filter(ansatz != "SEA+") %>%
    mutate(
        coeffs_abs = sqrt(coeffs_full_real^2 + coeffs_full_imag^2),
        coeffs_abs_real = abs(coeffs_full_real),
        coeffs_abs_imag = abs(coeffs_full_imag),
        coeffs_phase = atan(coeffs_full_imag / coeffs_full_real)
    ) %>%
    # Filter zero coefficients
    filter(coeffs_abs_mean > 1e-14)

for (n_qubits in list(6)) {
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
        distinct(noise_type, noise_value, ansatz, qubits, freq1, seed, sample_idx, .keep_all = TRUE) %>%
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
        )

    d_coeffs_summarised <- d_coeffs %>%
        filter(noise_value <= 0.03) %>%
        group_by(noise_type, noise_value, noise_category, ansatz, qubits, freq1) %>%
        summarise(
            mean_abs = mean(coeffs_abs),
            mean_phase = mean(coeffs_phase),
            sd_phase = sd(coeffs_phase),
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
            upper_bound = mean_abs + sd_abs,
            lower_bound = mean_abs - sd_abs,
            rel_sd = sd_abs / mean_abs,
        )

    d_coeffs_summarised$noise_category <- factor(d_coeffs_summarised$noise_category, levels = c("Decoherent Gate", "SPAM", "Damping", "Coh."))
    d_coeffs_summarised$noise_type <- factor(d_coeffs_summarised$noise_type,
        levels = c(
            "BitFlip", "PhaseFlip", "Depolarizing",
            "AmplitudeDamping", "PhaseDamping",
            "StatePreparation", "Measurement",
            "GateError"
        ),
        labels = c(
            "BF", "PF", "DP",
            "AD", "PD",
            "SP", "ME",
            "CGE"
        ),
    )


    single_qubit_freq_stuff <- function(g) {
        g <- g +
            geom_point(size = POINT.SIZE) +
            geom_line(linewidth = LINE.SIZE) +
            scale_colour_manual(ifelse(use_tikz, "$\\omega$", "Frequency"), values = COLOURS.LIST) +
            scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
            theme_paper() +
            guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE))) +
            theme(
                legend.margin = margin(b = -4)
            )
        return(g)
    }

    g <- ggplot(
        d_coeffs_summarised %>% filter(freq1 != 0),
        aes(x = noise_value, y = sd_phase, colour = freq1)
    ) +
        scale_y_continuous(ifelse(use_tikz, "$\\sigma_\\phi(\\omega)$ [log]", "SD Phase"),
            #breaks = scales::trans_breaks("log10", function(x) 10^x),
            #labels = trans_format("log10", math_format(10^.x))
        ) +
        facet_nested(ansatz ~ noise_category + noise_type,
            labeller = labeller(
                freq1 = frequencies_labeller,
                qubits = qubit_labeller,
            ),
        )
    g <- single_qubit_freq_stuff(g)
    save_name <- str_c("coeff_sd_phase_qubits", n_qubits)
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)

    g <- ggplot(
        d_coeffs_summarised %>% filter(freq1 != 0),
        aes(x = noise_value, y = mean_phase, colour = freq1)
    ) +
        scale_y_continuous(ifelse(use_tikz, "$\\sigma_\\phi(\\omega)$ [log]", "SD Phase"),
            #breaks = scales::trans_breaks("log10", function(x) 10^x),
            #labels = trans_format("log10", math_format(10^.x))
        ) +
        facet_nested(ansatz ~ noise_category + noise_type,
            labeller = labeller(
                freq1 = frequencies_labeller,
                qubits = qubit_labeller,
            ),
        )
    g <- single_qubit_freq_stuff(g)
    save_name <- str_c("coeff_mean_phase_qubits", n_qubits)
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)

    g <- ggplot(
        d_coeffs_summarised,
        aes(x = noise_value, y = mean_abs, colour = freq1)
    ) +
        scale_y_log10(ifelse(use_tikz, "$\\mu_c(\\omega)$ [log]", "|c| Mean [log]"),
            breaks = scales::trans_breaks("log10", function(x) 10^x),
            labels = trans_format("log10", math_format(10^.x))
        ) +
        facet_nested(ansatz ~ noise_category + noise_type,
            labeller = labeller(
                freq1 = frequencies_labeller,
                qubits = qubit_labeller,
            ),
        )
    g <- single_qubit_freq_stuff(g)
    save_name <- str_c("coeff_mean_qubits", n_qubits)
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)

    g <- ggplot(
        d_coeffs_summarised,
        aes(x = noise_value, y = rel_sd, colour = freq1)
    ) +
        # scale_y_log10(ifelse(use_tikz, "$\\sigma(\\lvert{c}_\\omega\\rvert)$ [log]", "|c| Standard Deviation [log]"),
        #     breaks = scales::trans_breaks("log10", function(x) 10^x),
        #     labels = trans_format("log10", math_format(10^.x))
        # )
        scale_y_continuous(ifelse(use_tikz, "$\\sigma_c(\\omega)$", "|c| Relative Standard Deviation"), ) +
        facet_nested(ansatz ~ noise_category + noise_type,
            labeller = labeller(
                freq1 = frequencies_labeller,
                qubits = qubit_labeller,
            ),
        )
    g <- single_qubit_freq_stuff(g)
    save_name <- str_c("coeff_sd_qubits", n_qubits)
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)


    d_coeffs_ansatz <- d_coeffs %>%
        filter(noise_value %in% c(0, 0.03) & noise_type %in% c("Depolarizing", "AmplitudeDamping"))
    d_coeffs_ansatz$noise_type[d_coeffs_ansatz$noise_value == 0] <- "Noiseless"
    d_coeffs_ansatz <- d_coeffs_ansatz %>% distinct(noise_type, noise_value, ansatz, qubits, freq1, seed, sample_idx, .keep_all = TRUE)
    d_coeffs_ansatz$noise_type <- factor(d_coeffs_ansatz$noise_type,
        levels = c(
            "Noiseless", "Depolarizing", "AmplitudeDamping"
        ),
        labels = c(
            "Noiseless", "DP", "AD"
        ),
    )

    g <- ggplot(d_coeffs_ansatz, aes(x = coeffs_full_real, y = coeffs_full_imag, colour = freq1)) +
        geom_point_rast(size = POINT.SIZE, alpha = 0.7, shape = 16, raster.dpi = 600) +
        facet_nested(noise_type ~ ansatz,
            labeller = labeller(
                freq1 = frequencies_labeller,
                qubits = qubit_labeller,
            ),
        ) +
        scale_colour_manual(ifelse(use_tikz, "$\\omega$", "Frequency"), values = COLOURS.LIST) +
        theme_paper() +
        scale_x_continuous("Real Part", limits = c(-0.3, 0.3)) +
        scale_y_continuous("Imaginary Part", limits = c(-0.3, 0.3)) +
        guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE))) +
        theme(
            legend.margin = margin(b = -6, t = 0)
        )
    save_name <- str_c("coeff_real_imag_qubits", n_qubits)
    create_plot(g, save_name, COLWIDTH, 0.28 * HEIGHT)
}
