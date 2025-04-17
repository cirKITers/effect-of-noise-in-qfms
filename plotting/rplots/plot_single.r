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

coeffs_1D_path <- "csv_data/single/coeffs_stat_dims1.csv"
coeffs_2D_path <- "csv_data/single/coeffs_stat_dims2.csv"
expr_path <- "csv_data/single/expr.csv"
ent_path <- "csv_data/single/ent.csv"

if(file.exists(coeffs_1D_path) | file.exists(coeffs_2D_path)) {
    if(file.exists(coeffs_1D_path))
        d_coeffs <- read_csv(coeffs_1D_path)
    else if(file.exists(coeffs_2D_path))
        d_coeffs <- read_csv(coeffs_2D_path)
    if(!"freq2" %in% colnames(d_coeffs))
    {
      d_coeffs$freq2 <- 0
    }

    d_coeffs <- d_coeffs %>%
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
    
    g <- ggplot(d_coeffs, aes(x = noise_value, y = mean_abs, colour = as.factor(freq1))) +
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
    
    save_name <- str_c("single/coeffs")
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)
    
    g <- ggplot(d_coeffs, aes(x = noise_value, y = rel_sd, colour = as.factor(freq1))) +
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
    
    save_name <- str_c("single/coeffs_sd")
    create_plot(g, save_name, COLWIDTH, 0.3 * HEIGHT)
    
    d_coeffs <- d_coeffs %>%
            filter(noise_value %in% c(0, 0.03))
    
    d_coeffs$noise_type[d_coeffs$noise_value == 0] <- "Noiseless"
    d_coeffs$noise_category[d_coeffs$noise_value == 0] <- ""
    d_coeffs <- d_coeffs %>% distinct(noise_type, noise_value, ansatz, qubits, freq1, .keep_all = TRUE) %>%
            pivot_longer(c(coeffs_var_real, coeffs_var_imag, coeffs_covar_ri), names_to = "var_type", values_to = "var")
    
    d_coeffs$var_type <- factor(
            d_coeffs$var_type,
            levels = c("coeffs_var_real", "coeffs_var_imag", "coeffs_covar_ri"),
            labels = c(
                                    "Re",
                                    "Im",
                                    "Re/Im"
            )
    )
    
    d_coeffs$var[d_coeffs$var < 1e-15] <- 0
    
    g <- ggplot(d_coeffs, aes(x = var_type, y = var, colour = noise_category, shape=noise_type)) +
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
    save_name <- str_c("single/coeff_covar")
    create_plot(g, save_name, COLWIDTH, d_coeffs$qubits * 0.1 * HEIGHT)
}

if(file.exists(expr_path)) {
    d_expr <- read_csv(coeffs_path)
    
    d_expr$ansatz <- factor(d_expr$ansatz,
        levels = c("Strongly_Entangling", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
        labels = c("SEA", "HEA", "Circuit 15", "Circuit 19")
    )
    
    d_expr <- d_expr %>%
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
            mean_expr = mean(expressibility),
            sd_expr = sd(expressibility),
            min_expr = min(expressibility),
            max_expr = max(expressibility)
        ) %>%
        mutate(
            upper_bound = max_expr,
            lower_bound = min_expr
        )
    
    d_expr <- d_expr %>%
        filter(!is.na(noise_value) & noise_value <= 0.03) %>%
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
    
    d_expr$noise_category <- factor(d_expr$noise_category, levels = c("Decoherent Gate", "Coherent", "SPAM", "Damping", "Coh."))
    
    d_expr$noise_type <- factor(d_expr$noise_type,
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
            "GE"
        ),
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
        facet_nested(noise_category + noise_type ~ ansatz,
            labeller = labeller(
                frequency = frequencies_labeller,
                qubits = qubit_labeller,
            ),
        ) +
        scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
        theme_paper() +
        guides(colour = guide_legend(nrow = 1)) +
        scale_y_log10(
            ifelse(use_tikz, "\\small{more expressive} \\normalsize{$\\leftarrow\\qquad$ KL-Divergence [log] $\\qquad \\rightarrow$} \\small{less expressive}", "KL-Divergence [log]"),
            breaks = c(1e-2, 1e0, 1e2),
            labels = trans_format("log10", math_format(10^.x)),
        ) +
        theme(
            legend.margin = margin(b = -4),
            legend.key.height = unit(0.2, "cm"),
            legend.key.width = unit(0.2, "cm")
        )

    save_name <- str_c("single/expr")
    create_plot(g, save_name, COLWIDTH, 0.38 * HEIGHT)

}

if(file.exists(ent_path)) {
    d_ent <- read_csv(ent_path)

    d_ent$ansatz <- factor(d_ent$ansatz,
        levels = c("Strongly_Entangling", "Hardware_Efficient", "Circuit_15", "Circuit_19"),
        labels = c("SEA", "HEA", "Circuit 15", "Circuit 19")
    )
    d_ent <- d_ent %>%
        pivot_longer(
            c(
                BitFlip, PhaseFlip, Depolarizing,
                AmplitudeDamping, PhaseDamping, GateError,
                StatePreparation, Measurement,
            ),
            names_to = "noise_type", values_to = "noise_value"
        ) %>%
        distinct(noise_type, noise_value, ansatz, qubits, seed, measure, .keep_all = TRUE) %>%
        group_by(noise_type, noise_value, ansatz, qubits, measure) %>%
        summarise(
            mean_ent = mean(entangling_capability),
            sd_ent = sd(entangling_capability),
            max_ent = max(entangling_capability),
            min_ent = min(entangling_capability)
        ) %>%
        mutate(
            upper_bound = max_ent,
            lower_bound = min_ent
        )
    
    d_ent <- d_ent %>%
        filter(!is.na(noise_value) & (noise_value == 0 | noise_value > 0.0045)) %>%
        mutate(
            noise_category = ifelse(
                noise_type %in% c("BitFlip", "PhaseFlip", "Depolarizing"),
                "Decoherent Gate",
                ifelse(
                    noise_type %in% c("StatePreparation", "Measurement"),
                    "SPAM",
                    ifelse(noise_type == "GateError",
                        "Coh.",
                        "Damping"
                    )
                )
            ),
        )
    
    d_ent$noise_category <- factor(d_ent$noise_category, levels = c("Decoherent Gate", "SPAM", "Damping", "Coh."))
    
    d_ent$noise_type <- factor(d_ent$noise_type,
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

    g <- ggplot(
        d_ent,
        aes(x = noise_value, colour = as.factor(qubits))
    ) +
        geom_point(aes(y = mean_ent), size = POINT.SIZE) +
        geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound, fill = as.factor(qubits)), alpha = 0.5, colour = NA) +
        geom_line(aes(y = mean_ent), linewidth = LINE.SIZE) +
        scale_colour_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
        scale_fill_manual(ifelse(use_tikz, "\\# Qubits", "# Qubits"), values = COLOURS.LIST) +
        facet_nested(noise_category + noise_type ~ ansatz,
            labeller = labeller(
                frequency = frequencies_labeller,
                qubits = qubit_labeller,
            ),
            scale = "free_x",
        ) +
        scale_x_continuous("Noise Level", labels = ifelse(use_tikz, latex_percent, scales::percent), breaks = seq(0, 1, 0.01)) +
        scale_y_log10("Entangling Capability [log]") +
        theme_paper() +
        guides(
            colour = guide_legend(nrow = 1),
            shape = guide_legend(nrow = 1, theme = theme(legend.byrow = TRUE), override.aes = list(alpha = 1, size = 3 * POINT.SIZE))
        ) +
        theme(
            legend.margin = margin(b = -4),
            legend.key.height = unit(0.2, "cm"),
            legend.key.width = unit(0.2, "cm")
        ) +
        force_panelsizes(cols = c(2, 5))

    save_name <- str_c("single/ent")
    create_plot(g, save_name, COLWIDTH, 0.38 * HEIGHT)
}
