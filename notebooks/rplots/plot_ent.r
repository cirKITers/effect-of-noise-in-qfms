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

coeffs_path <- "csv_data/entanglement.csv"
d_ent <- read_csv(coeffs_path)

index_labeller <- function(layer) {
  paste0("i = ", layer)
}

# d_ent$ansatz <- gsub("_", " ", d_ent$ansatz)
d_ent$ansatz <- factor(d_ent$ansatz, labels = c("Strongly_Entangling" = "SEA", "Hardware_Efficient" = "HEA", "Circuit_15" = "Circuit 15", "Circuit_19" = "Circuit 19"))
d_ent <- d_ent %>%
  pivot_longer(
    c(
      BitFlip, PhaseFlip, Depolarizing,
      AmplitudeDamping, PhaseDamping, GateError,
      StatePreparation, Measurement,
    ),
    names_to = "noise_type", values_to = "noise_value"
  ) %>%
  distinct(noise_type, noise_value, ansatz, qubits, seed, .keep_all = TRUE) %>%
  group_by(noise_type, noise_value, ansatz, qubits) %>%
  summarise(
    mean_ent = mean(entangling_capability),
    sd_ent = sd(entangling_capability),
    max_ent = max(entangling_capability),
    min_ent = min(entangling_capability)
  ) %>%
  mutate(
    #upper_bound = mean_ent + sd_ent,
    #lower_bound = mean_ent - sd_ent
    upper_bound = max_ent,
    lower_bound = min_ent
  )

d_ent <- d_ent %>%
    filter(!is.na(noise_value)) %>%
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

d_ent$noise_category <- factor(d_ent$noise_category, levels = c("Decoherent Gate", "Coherent", "SPAM", "Damping"))

d_ent$noise_type <- factor(d_ent$noise_type,
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


d_7_qubits <- d_ent %>%
  filter(qubits == 7)

g <- ggplot(
  d_ent,
  aes(x = noise_value, colour = as.factor(qubits))
) +
  geom_point(aes(y = mean_ent), size = POINT.SIZE) +
  geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound, fill = as.factor(qubits)), alpha = 0.5, colour = NA) +
  geom_line(aes(y = mean_ent), linewidth = LINE.SIZE) +
  scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
  scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
  facet_nested(ansatz ~ noise_category + noise_type,
    labeller = labeller(
      frequency = frequencies_labeller,
      qubits = qubit_labeller,
    ),
  ) +
  scale_x_continuous("Noise Probability", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.02)) +
  scale_y_continuous("Entangling Capability") +
  theme_paper() +
  guides(colour = guide_legend(nrow = 1))

save_name <- str_c("ent")
create_plot(g, save_name, TEXTWIDTH, 0.3 * HEIGHT)
