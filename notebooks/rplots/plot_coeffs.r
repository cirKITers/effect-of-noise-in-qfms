#!/usr/bin/env Rscript

library(tidyverse)
library(ggh4x)
library(tikzDevice)
library(scales)
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

coeffs_path <- "csv_data/coeffs.csv"

d_coeffs <- read_csv(coeffs_path)

index_labeller <- function(layer) {
  paste0("i = ", layer)
}

# d_coeffs$ansatz <- gsub("_", " ", d_coeffs$ansatz)
d_coeffs$ansatz <- factor(d_coeffs$ansatz, labels = c("Strongly_Entangling" = "SEA", "Hardware_Efficient" = "HEA", "Circuit_15" = "Circuit 15", "Circuit_19" = "Circuit 19"))
d_coeffs$frequency <- as.factor(d_coeffs$frequency)
d_coeffs$frequencies <- as.factor(d_coeffs$frequencies)
d_coeffs <- d_coeffs %>% pivot_longer(
  c(
    BitFlip, PhaseFlip, Depolarizing,
    AmplitudeDamping, PhaseDamping, ThermalRelaxation,
    StatePreparation, Measurement,
  ),
  names_to = "noise_type", values_to = "noise_value"
)

d_coeffs$noise_type <- factor(d_coeffs$noise_type,
  levels = c(
    "BitFlip", "PhaseFlip", "Depolarizing",
    "AmplitudeDamping", "PhaseDamping", "ThermalRelaxation",
    "StatePreparation", "Measurement"
  )
)
d_coeffs <- d_coeffs[!is.na(d_coeffs$noise_value), ] %>% filter(noise_type != "ThermalRelaxation")

d_coeffs <- d_coeffs %>%
  group_by(noise_type, noise_value, ansatz, qubits, frequency) %>%
  summarise(
    coeffs_abs_var = mean(coeffs_abs_var),
    coeffs_abs_mean = mean(coeffs_abs_mean),
  ) %>%
  mutate(noise_category = ifelse(
    noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
    "Gate",
    ifelse(
      noise_type %in% c("Measurement", "StatePreparation"),
      "SPAM",
      "Environmental"
    )
  ))

d_coeffs$noise_category <- factor(d_coeffs$noise_category, levels = c("Gate", "SPAM", "Environmental"))

d_coeffs <- d_coeffs %>%
  filter(coeffs_abs_mean > 1e-15)

d_7_qubits <- d_coeffs %>%
  filter(qubits == 7)

single_qubit_freq_stuff <- function(g) {
  g <- g +
    geom_point(size = POINT.SIZE) +
    geom_line(linewidth = LINE.SIZE) +
    scale_colour_manual("Frequency", values = COLOURS.LIST) +
    facet_nested(ansatz ~ noise_category + noise_type,
      labeller = labeller(
        frequency = frequencies_labeller,
        qubits = qubit_labeller,
      ),
      scale = "free_x"
    ) +
    scale_x_continuous("Noise Probability", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
    theme_paper() +
    theme(
      legend.key.width = unit(4, "mm"),
    ) +
    guides(colour = guide_legend(nrow = 1)) +
    scale_y_log10("Coefficient Mean [log]",
      breaks = scales::trans_breaks("log10", function(x) 10^x),
      labels = trans_format("log10", math_format(10^.x))
    )
  return(g)
}

g <- ggplot(
  d_7_qubits,
  aes(x = noise_value, y = coeffs_abs_mean, colour = frequency)
)
g <- single_qubit_freq_stuff(g)
save_name <- str_c("coeff_mean_7_qubits")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)

g <- ggplot(
  d_7_qubits,
  aes(x = noise_value, y = coeffs_abs_var, colour = frequency)
)
g <- single_qubit_freq_stuff(g)
save_name <- str_c("coeff_var_7_qubits")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)
