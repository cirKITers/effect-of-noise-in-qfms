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

coeffs_path <- "csv_data/expr.csv"
d_expr <- read_csv(coeffs_path)

index_labeller <- function(layer) {
  paste0("i = ", layer)
}

# d_expr$ansatz <- gsub("_", " ", d_expr$ansatz)
d_expr$ansatz <- factor(d_expr$ansatz, labels = c("Strongly_Entangling" = "SEA", "Hardware_Efficient" = "HEA", "Circuit_15" = "Circuit 15", "Circuit_19" = "Circuit 19"))
d_expr <- d_expr %>%
  pivot_longer(
    c(
      BitFlip, PhaseFlip, Depolarizing,
      AmplitudeDamping, PhaseDamping, ThermalRelaxation,
      StatePreparation, Measurement,
    ),
    names_to = "noise_type", values_to = "noise_value"
  ) %>%
  distinct(noise_type, noise_value, ansatz, qubits, seed, .keep_all = TRUE) %>%
  group_by(noise_type, noise_value, ansatz, qubits) %>%
  summarise(
    mean_expr = mean(expressibility),
    sd_expr = sd(expressibility)
  ) %>%
  mutate(
    upper_bound = mean_expr + sd_expr,
    lower_bound = mean_expr - sd_expr
  )

d_expr$noise_type <- factor(d_expr$noise_type,
  levels = c(
    "BitFlip", "PhaseFlip", "Depolarizing",
    "AmplitudeDamping", "PhaseDamping", "ThermalRelaxation",
    "StatePreparation", "Measurement"
  )
)
d_expr <- d_expr[!is.na(d_expr$noise_value), ] %>% filter(noise_type != "ThermalRelaxation")

d_expr <- d_expr %>%
  mutate(noise_category = ifelse(
    noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
    "Gate",
    ifelse(
      noise_type %in% c("Measurement", "StatePreparation"),
      "SPAM",
      "Environmental"
    )
  ))

d_expr$noise_category <- factor(d_expr$noise_category, levels = c("Gate", "SPAM", "Environmental"))

d_7_qubits <- d_expr %>%
  filter(qubits == 7)

gate_noise_scale <- scale_y_log10(
  "KL-Divergence [log]",
  breaks = scales::trans_breaks("log10", function(x) 10^x),
  labels = trans_format("log10", math_format(10^.x)),
  limits = c(10e-4, 130),
)
gate_noise_scale_no_guide <- scale_y_log10(
  "KL-Divergence",
  breaks = scales::trans_breaks("log10", function(x) 10^x),
  labels = trans_format("log10", math_format(10^.x)),
  limits = c(10e-4, 130),
  guide = "none"
)

spam_noise_scale <- scale_y_log10(
  "KL-Divergence [log]",
  breaks = scales::trans_breaks("log10", function(x) 10^x),
  labels = trans_format("log10", math_format(10^.x)),
  limits = c(10e-4,2)
)

spam_noise_scale_no_guide <- scale_y_log10(
  guide = "none",
  limits = c(10e-4,2)
)

env_noise_scale <- scale_y_continuous(
  "KL-Divergence",
  limits = c(0,1)
)

env_noise_scale_no_guide <- scale_y_continuous(
  guide = "none",
  limits = c(0,1)
)


g <- ggplot(
  d_expr,
  aes(x = noise_value, y = mean_expr, colour = as.factor(qubits))
) +
  geom_point(size = POINT.SIZE) +
  geom_line(linewidth = LINE.SIZE) +
  geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound, fill = as.factor(qubits)), alpha = 0.5, colour = NA) +
  scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
  scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
  facet_nested(ansatz ~ noise_category + noise_type,
    labeller = labeller(
      frequency = frequencies_labeller,
      qubits = qubit_labeller,
    ),
    scale = "free_y",
    independent = "y",
  ) +
  scale_x_continuous("Noise Probability", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
  theme_paper() +
  guides(colour = guide_legend(nrow = 1)) +
  facetted_pos_scales(
    y = list(
      noise_type == "BitFlip" ~ gate_noise_scale,
      noise_type == "PhaseFlip" ~ gate_noise_scale_no_guide,
      noise_type == "Depolarizing" ~ gate_noise_scale_no_guide,
      noise_type == "StatePreparation" ~ spam_noise_scale,
      noise_type == "Measurement" ~ spam_noise_scale_no_guide,
      noise_type == "AmplitudeDamping" ~ spam_noise_scale_no_guide,
      noise_type == "PhaseDamping" ~ spam_noise_scale_no_guide
    )
  )

save_name <- str_c("expr")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)
