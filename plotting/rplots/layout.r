BASE.SIZE <- 8
INCH.PER.CM <- 1 / 2.54
TEXTWIDTH <- 13.07245 * INCH.PER.CM
COLWIDTH <- 13.07245 * INCH.PER.CM
HEIGHT <- 19.42224 * INCH.PER.CM
OUTDIR_PDF <- "img-pdf/"
OUTDIR_TIKZ <- "img-tikz/"
COLOURS.LIST <- c("black", "#E69F00", "#999999", "#009371", "#beaed4", "#ed665a", "#1f78b4", "#CC79A7", "red", "blue")
POINT.SIZE <- 0.3
LINE.SIZE <- 0.5

use_tikz <- TRUE

theme_paper <- function() {
  return(theme_bw(base_size = BASE.SIZE) +
    theme(
      strip.background = element_rect(colour = "black", fill = "white"),
      axis.title.x = element_text(size = BASE.SIZE),
      axis.title.y = element_text(size = BASE.SIZE),
      legend.title = element_text(size = BASE.SIZE),
      legend.position = "top",
      plot.margin = unit(c(0, 0, 0, 0), "cm"),
      legend.margin = margin(b = -4),
      legend.key.height = unit(0.4, "cm"),
      legend.key.width = unit(0.4, "cm")
    ))
}

create_plot <- function(g, save_name, w, h) {
  if (use_tikz) {
    tikz(
      str_c(OUTDIR_TIKZ, save_name, ".tex"),
      width = w, height = h
    )
  } else {
    pdf(
      str_c(OUTDIR_PDF, save_name, ".pdf"),
      width = w, height = h
    )
  }
  print(g)
  dev.off()
  if (!use_tikz)
    print(str_c("Created plot in ", getwd(), "/", OUTDIR_PDF, save_name, ".pdf"))
}

qubit_labeller <- function(layer) {
  if (use_tikz) {
    paste0("\\# Qubits = ", layer)
  } else {
    paste0("# Qubits = ", layer)
  }
}

feature_labeller <- function(layer) {
    paste0(ifelse(use_tikz, "$D$", "D"), " = ", layer)
}

circuit_labeller <- function(layer) {
  paste0("Circuit ", layer)
}

problem_labeller <- function(layer) {
  paste0("Problem Seed=", layer)
}

frequencies_labeller <- function(layer) {
    paste0(ifelse(use_tikz, "${\\boldsymbol{\\omega}}$", "w"), " = ", layer)
}

freq1_labeller <- function(layer) {
    paste0(ifelse(use_tikz, "${\\boldsymbol{\\omega}}^{(1)}$", "w1"), " = ", layer)
}

freq2_labeller <- function(layer) {
    paste0(ifelse(use_tikz, "${\\boldsymbol{\\omega}}^{(2)}$", "w2"), " = ", layer)
}

latex_percent <- function (x) {
    stringr::str_c(x * 100, "\\%")
}
