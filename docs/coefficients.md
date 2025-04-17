# Coefficients

The resulting plots of our experiments as PDF can be found in [plotting/rplots/img-gen](plotting/rplots/img-gen), while a PNG version can be found below.

## Summary

Our Figure 8 in the paper summarised the coefficient mean $\mu_c(\boldsymbol{\omega})$ for 1D, and 2D inputs and all qubits, only depicting the zero and maximum frequency-coefficient, shown here:
![Coefficients Mean Summary](figures/coeff_abs_mean_light.png#only-light)
![Coefficients Mean Summary](figures/coeff_abs_mean_dark.png#center#only-dark)
Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for the lowest frequency $\boldsymbol{\omega}=\boldsymbol{0}$ and highest frequency $\boldsymbol{\omega} = \boldsymbol{\omega}_\text{max}$ in the respective spectrum under the influence of varying noise levels. We considered one-dimensional ($D$ = 1), and two-dimensional inputs ($D$ = 2). The y-axis for each facet row are equal throughout the respective $\boldsymbol{\omega}$, but differs in between.

The corresponding relative standard deviation is
![Coefficients Mean Summary](figures/coeff_abs_sd_light.png#only-light)
![Coefficients Mean Summary](figures/coeff_abs_sd_dark.png#only-dark)
Relative standard deviation $\sigma_c(\boldsymbol{\omega})$.

The detailed mean and standard deviations for varying qubit counts can be found in the corresponding pages on [1D-coefficients](coefficients1d.md) and [2D-coefficients](coefficients2d.md).

Our Figure 9 in the paper:
![Coefficients Num Freq](figures/n_freqs_light.png#only-light)
![Coefficients Num Freq](figures/n_freqs_dark.png#only-dark)

## Input Encoding

Our Figure 3 from the paper:
![Coefficients Encoding Mean](figures/coeff_mean_encoding_light.png#only-light)
![Coefficients Encoding Mean](figures/coeff_mean_encoding_dark.png#only-dark)
Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies.

And the corresponding relative standard deviation:
![Coefficients Encoding Standard Deviation](figures/coeff_sd_encoding_light.png#only-light)
![Coefficients Encoding Standard Deviation](figures/coeff_sd_encoding_dark.png#only-dark)
Absolute coefficient standard deviation $\sigma_c(\boldsymbol{\omega})$ for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies.

Our Figure 4 from the paper:
![Coefficients Encoding Real/Imag](figures/coeff_real_imag_encoding_light.png#only-light)
![Coefficients Encoding Real/Imag](figures/coeff_real_imag_encoding_dark.png#only-dark)
Coefficients, separated into real and imaginary parts for a circuit with six qubits and different single qubit Pauli-encodings.
