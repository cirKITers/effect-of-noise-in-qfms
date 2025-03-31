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

d_coeffs$ansatz <- factor(d_coeffs$ansatz,
    levels = c("Strongly_Entangling", "Strongly_Entangling_Plus", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
    labels = c("SEA", "SEA+", "HEA", "Circuit 15", "Circuit 19")
)
d_coeffs$freq1 <- as.factor(d_coeffs$freq1)

d_coeffs <- d_coeffs %>%
    filter(qubits == 6)
d_coeffs <- d_coeffs %>%
    mutate(
        coeffs_abs = sqrt(coeffs_full_real^2 + coeffs_full_imag^2),
        coeffs_abs_real = abs(coeffs_full_real),
        coeffs_abs_imag = abs(coeffs_full_imag)
    ) %>%
    # Filter zero coefficients
    filter(coeffs_abs > 1e-14)

d_coeffs <- d_coeffs %>% distinct(ansatz, qubits, freq1, seed, encoding, sample_idx, .keep_all = TRUE)

g <- ggplot(d_coeffs, aes(x = coeffs_full_real, y = coeffs_full_imag, colour = freq1)) +
    geom_point_rast(size = POINT.SIZE, alpha = 0.7, shape = 16, raster.dpi = 600) +
    facet_nested(ansatz ~ encoding,
        labeller = labeller(
            freq1 = frequencies_labeller,
            qubits = qubit_labeller,
        ),
    ) +
    scale_colour_manual("Frequency", values = COLOURS.LIST) +
    theme_paper() +
    scale_x_continuous("Real Part", limits = c(-0.3, 0.3)) +
    scale_y_continuous("Imaginary Part", limits = c(-0.3, 0.3)) +
    guides(colour = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE)), override.aes = list(alpha = 1, size = 2 * POINT.SIZE)) +
    theme(
        legend.margin = margin(b = -4, t = 0)
    )
save_name <- str_c("coeff_real_imag_encoding")
create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)
