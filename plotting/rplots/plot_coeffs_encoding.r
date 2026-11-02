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

coeffs_path <- "csv_data/coeffs_enc_full_dims1.csv"

d_coeffs <- read_csv(coeffs_path)

index_labeller <- function(layer) {
    paste0("i = ", layer)
}

d_coeffs$ansatz <- ansatz_to_factor(d_coeffs$ansatz)
d_coeffs$frequency <- as.factor(d_coeffs$freq1)
if (use_tikz) {
    d_coeffs$encoding <- factor(d_coeffs$encoding, labels = c("$R_X$", "$R_Y$", "$R_Z$"))
}

d_coeffs <- d_coeffs %>%
    mutate(
        coeffs_abs = sqrt(coeffs_full_real^2 + coeffs_full_imag^2),
        coeffs_abs_real = abs(coeffs_full_real),
        coeffs_abs_imag = abs(coeffs_full_imag),
    )

d_coeffs <- d_coeffs %>%
    distinct(ansatz, qubits, frequency, seed, encoding, sample_idx, .keep_all = TRUE)

g <- ggplot(d_coeffs %>% filter(qubits == 6 & coeffs_abs > 1e-14), aes(x = coeffs_full_real, y = coeffs_full_imag, colour = frequency)) +
    geom_point_rast(size = POINT.SIZE, alpha = 0.7, shape = 16, raster.dpi = 600) +
    facet_nested(encoding ~ ansatz,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_colour_manual(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "Frequency"), values = COLOURS.LIST) +
    theme_paper() +
    scale_x_continuous("Real Part", limits = c(-0.3, 0.3)) +
    scale_y_continuous("Imaginary Part", limits = c(-0.3, 0.3)) +
    guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE)))
save_name <- str_c("coeff_real_imag_encoding")
create_plot(g, save_name, 0.6 * TEXTWIDTH, 0.3 * HEIGHT)

d_coeffs <- d_coeffs %>%
    distinct(ansatz, qubits, freq1, encoding, seed, .keep_all = TRUE) %>%
    mutate(coeffs_abs_mean = ifelse(coeffs_abs_mean < 1e-14, NA, coeffs_abs_mean)) %>%
    group_by(ansatz, qubits, freq1, encoding) %>%
    summarise(
        mean_coeff = mean(coeffs_abs_mean),
        sd_coeff = mean(sqrt(coeffs_abs_var)),
        relative_sd = mean(sqrt(coeffs_abs_var) / coeffs_abs_mean)
    ) %>%
    filter(!is.na(mean_coeff)) %>%
    mutate(
        upper_bound = mean_coeff + sd_coeff,
        lower_bound = mean_coeff - sd_coeff,
    )

d_coeffs$qubits <- factor(d_coeffs$qubits, levels = c(6, 5, 4, 3))
d_coeffs <- d_coeffs %>% arrange(qubits)

g <- ggplot(d_coeffs, aes(x = freq1, y = mean_coeff, colour = qubits)) +
    geom_line(linewidth = LINE.SIZE) +
    geom_point(size = POINT.SIZE) +
    facet_nested(encoding ~ ansatz,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_x_continuous(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "Frequency")) +
    scale_y_log10(ifelse(use_tikz, "$\\mu_c({\\boldsymbol{\\omega}})$ [log]", "|c| Mean [log]"),
        breaks = scales::trans_breaks("log10", function(x) 10^x),
        labels = trans_format("log10", math_format(10^.x))
    ) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = rev(head(COLOURS.LIST, 4))) +
    theme_paper() +
    guides(colour = guide_legend(reverse = T))

save_name <- str_c("coeff_mean_encoding")
create_plot(g, save_name, 0.48 * COLWIDTH, 0.25 * HEIGHT)

g <- ggplot(d_coeffs, aes(x = freq1, y = relative_sd, colour = qubits)) +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    facet_nested(encoding ~ ansatz,
        labeller = labeller(
            frequency = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_x_continuous(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "Frequency")) +
    # the relative SD spans less than one decade, so power-of-ten breaks
    # would fall on fractional exponents and overlap; use plain numbers
    scale_y_log10(ifelse(use_tikz, "$\\sigma_c({\\boldsymbol{\\omega}})$ [log]", "|c| Relative Standard Deviation [log]"),
        breaks = c(0.5, 1, 2, 4),
        labels = c("0.5", "1", "2", "4")
    ) +
    scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = rev(head(COLOURS.LIST, 4))) +
    theme_paper() +
    guides(colour = guide_legend(reverse = T))

save_name <- str_c("coeff_sd_encoding")
create_plot(g, save_name, 0.48 * TEXTWIDTH, 0.25 * HEIGHT)
