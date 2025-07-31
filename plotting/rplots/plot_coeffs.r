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

coeffs_path <- "csv_data/coeffs_full_dims1_q6_AmplitudeDamping.csv"

d_coeffs <- read_csv(coeffs_path)
d_coeffs <- d_coeffs %>% filter(qubits == 6)

d_coeffs$ansatz <- factor(d_coeffs$ansatz,
    levels = c("Strongly_Entangling", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "HEA", "Circuit 15", "Circuit 19")
)
d_coeffs$freq1 <- as.factor(d_coeffs$freq1)

d_coeffs <- d_coeffs %>%
    mutate(
        coeffs_abs = sqrt(coeffs_full_real^2 + coeffs_full_imag^2),
        coeffs_abs_real = abs(coeffs_full_real),
        coeffs_abs_imag = abs(coeffs_full_imag)
    ) %>%
    # Filter zero coefficients
    filter(coeffs_abs > 1e-14)

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
save_name <- str_c("coeff_real_imag_qubits6")
create_plot(g, save_name, COLWIDTH, 0.28 * HEIGHT)

g <- ggplot(d_coeffs_ansatz %>% filter(noise_type %in% c("Noiseless", "AD") & freq1 == 0), aes(x = coeffs_full_real, y = "none", colour = noise_type, shape = noise_type)) +
    geom_boxplot(lwd = 0.3, outlier.size = 0.05 * POINT.SIZE) +
    facet_nested(. ~ ansatz,
        labeller = labeller(
            freq1 = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_colour_manual("", values = c(COLOURS.LIST[1],COLOURS.LIST[4])) +
    scale_shape_manual("", values = c(19, 15)) +
    theme_paper() +
    scale_x_continuous(ifelse(use_tikz, "$c_{\\boldsymbol{0}}(\\boldsymbol{\\theta})$", "c"), limits = c(-0.3, 0.3)) +
    scale_y_discrete("", breaks = c("Noiseless", "AD")) +
    theme(
        legend.margin = margin(b = -4, t = 0),
        axis.text.y = element_blank(),
        legend.key.height = unit(0.2, "cm"),
    )
save_name <- str_c("coeff_real_AD_qubits6")
create_plot(g, save_name, 0.6 * TEXTWIDTH, 0.15 * HEIGHT)
