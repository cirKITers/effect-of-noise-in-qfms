# Coefficients

The resulting plots of our experiments as PDF can be found in [plotting/rplots/img-gen](https://github.com/cirKITers/effect-of-noise-in-qfms/tree/main/plotting/rplots/img-gen), while a PNG version can be found on this website.

## Summary

Our Figure 16 in the paper summarised the coefficient mean $\mu_c(\boldsymbol{\omega})$ for 1D ($R_X$ and $R_Y$ encoding), and 2D ($R_X R_Y$ encoding) inputs and all qubits, only depicting the zero and maximum frequency-coefficient, shown here:
![Coefficients Mean Summary](figures/coeff_abs_mean_light.png#only-light)
![Coefficients Mean Summary](figures/coeff_abs_mean_dark.png#center#only-dark)

Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for the lowest frequency $\boldsymbol{\omega}=\boldsymbol{0}$ and highest frequency $\boldsymbol{\omega} = \boldsymbol{\omega}_\text{max}$ in the respective spectrum under the influence of varying noise levels. We considered one-dimensional encodings $R_X$ and $R_Y$ ($D$ = 1), and a two-dimensional encoding $R_X R_Y$ ($D$ = 2). The y-axis for each facet row are equal throughout the respective $\boldsymbol{\omega}$, but differs in between.

The corresponding relative standard deviation is (Our Figure 17 in the paper)
![Coefficients Mean Summary](figures/coeff_abs_sd_light.png#only-light)
![Coefficients Mean Summary](figures/coeff_abs_sd_dark.png#only-dark)

Relative standard deviation $\sigma_c(\boldsymbol{\omega})$ for the absolute coefficient mean values from Fig. 16.

The detailed mean and standard deviations for varying qubit counts and encodings can be found in the corresponding pages on [coefficients RX](coefficients1d_rx.md), [coefficients RY](coefficients_ry.md) and [2D-coefficients](coefficients2d.md).


## Influence of Input Encoding

We measure the coefficients for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies in a noiseless setting.

Our Figure 2a from the paper:
![Coefficients Encoding Mean](figures/coeff_mean_encoding_light.png#only-light)
![Coefficients Encoding Mean](figures/coeff_mean_encoding_dark.png#only-dark)

Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$.


And the corresponding relative standard deviation (Our Figure 2b in the paper):
![Coefficients Encoding Standard Deviation](figures/coeff_sd_encoding_light.png#only-light)
![Coefficients Encoding Standard Deviation](figures/coeff_sd_encoding_dark.png#only-dark)

Relative standard deviation $\sigma_c(\boldsymbol{\omega})$ for the absolute coefficient mean values from Fig. 2a.


Our Figure 3 from the paper:
![Coefficients Encoding Real/Imag](figures/coeff_real_imag_encoding_light.png#only-light)
![Coefficients Encoding Real/Imag](figures/coeff_real_imag_encoding_dark.png#only-dark)

Coefficients, separated into real and imaginary parts for a circuit with six qubits and different single qubit Pauli-encodings. The individual frequency components are colour-coded.


## Effect of Coherent Noise

Our Figure 7 in the paper:
![Coefficients Num Freq](figures/coeff_mean_subsampling_light.png#only-light)
![Coefficients Num Freq](figures/coeff_mean_subsampling_dark.png#only-dark)

Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for 6 qubits and $R_Y$ encodings over frequencies for different noise levels $[0,\dots,3]\%$ and different ansätze. Noise is applied either on the encoding gates ($\bepsilon_{\bx}$), the trainable gates ($\bepsilon_{\btheta}$) or on the full VQC ($\bepsilon_{\bx}$ and $\bepsilon_{\btheta}$).


Our Figure 8 in the paper:
![Coefficients Num Freq](figures/n_freqs_light.png#only-light)
![Coefficients Num Freq](figures/n_freqs_dark.png#only-dark)

Number of frequencies in the spectrum with and without applying a coherent gate error for $D$-dimensional inputs and only those circuits where the maximum possible number of frequencies is not achieved in the noiseless case.
