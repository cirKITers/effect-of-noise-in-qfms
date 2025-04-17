# Results

On this page you can find links and explaination to supplementary results of our paper.

## Coefficients

The resulting plots of our experiments as PDF can be found in [this subdirectory](rplots/img-gen), while a PNG version can be found below.

### Summary

Our Figure 8 in the paper summarised the coefficient mean $\mu_c(\boldsymbol{\omega})$ for 1D, and 2D inputs and all qubits, only depicting the zero and maximum frequency-coefficient, shown here:
![Coefficients Mean Summary](../docs/figures/coeff_abs_mean_light.png)
(Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for the lowest frequency $\boldsymbol{\omega}=\boldsymbol{0}$ and highest frequency $\boldsymbol{\omega} = \boldsymbol{\omega}_\text{max}$ in the respective spectrum under the influence of varying noise levels. We considered one-dimensional ($D$ = 1), and two-dimensional inputs ($D$ = 2). The y-axis for each facet row are equal throughout the respective $\boldsymbol{\omega}$, but differs in between.)

The corresponding relative standard deviation is
![Coefficients Mean Summary](../docs/figures/coeff_abs_sd_light.png)
(Relative standard deviation $\sigma_c(\boldsymbol{\omega})$.)

The detailed mean and standard deviations for varying qubit counts can be found in the corresponding sections on [1D-coefficients](#1d-coefficients) and [2D-coefficients](#2d-coefficients).

Our Figure 9 in the paper:
![Coefficients Num Freq](../docs/figures/n_freqs_light.png).

### Input Encoding

Our Figure 3 from the paper:
![Coefficients Encoding Mean](../docs/figures/coeff_mean_encoding_light.png)
(Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies.)

And the corresponding relative standard deviation:
![Coefficients Encoding Standard Deviation](../docs/figures/coeff_sd_encoding_light.png)
(Absolute coefficient standard deviation $\sigma_c(\boldsymbol{\omega})$ for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies.)

Our Figure 4 from the paper:
![Coefficients Encoding Real/Imag](../docs/figures/coeff_real_imag_encoding_light.png)
(Coefficients, separated into real and imaginary parts for a circuit with six qubits and different single qubit Pauli-encodings.)

### 1D Coefficients

We show the the coefficient mean $\mu_c(\boldsymbol{\omega})$, the corresponding relative standard deviation $\mu_c(\boldsymbol{\omega})$ and Covariance of real and imaginary parts. In the paper these would correspond to Figure 7a, 7b and 5, respectively for the six qubit case. Shown here are the plots for all qubit numbers.

#### 3 Qubits

Mean:
![Coefficients 3 Qubits - Mean](../docs/figures/coeff_mean_qubits3_light.png)

Relative Standard Deviation:
![Coefficients 3 Qubits - Mean](../docs/figures/coeff_sd_qubits3_light.png)

Covariance:
![Coefficients 3 Qubits - Mean](../docs/figures/coeff_covar_qubits3_light.png)


#### 4 Qubits

Mean:
![Coefficients 4 Qubits - Mean](../docs/figures/coeff_mean_qubits4_light.png)

Relative Standard Deviation:
![Coefficients 4 Qubits - Mean](../docs/figures/coeff_sd_qubits4_light.png)

Covariance:
![Coefficients 4 Qubits - Mean](../docs/figures/coeff_covar_qubits4_light.png)


#### 5 Qubits

Mean:
![Coefficients 5 Qubits - Mean](../docs/figures/coeff_mean_qubits5_light.png)

Relative Standard Deviation:
![Coefficients 5 Qubits - Mean](../docs/figures/coeff_sd_qubits5_light.png)

Covariance:
![Coefficients 5 Qubits - Mean](../docs/figures/coeff_covar_qubits5_light.png)


#### 6 Qubits

Mean (Figure 7a in our paper):
![Coefficients 6 Qubits - Mean](../docs/figures/coeff_mean_qubits6_light.png)

Relative Standard Deviation (Figure 7b in our paper):
![Coefficients 6 Qubits - Mean](../docs/figures/coeff_sd_qubits6_light.png)

Covariance (Figure 5 in our paper):
![Coefficients 6 Qubits - Mean](../docs/figures/coeff_covar_qubits6_light.png)


### 2D Coefficients

#### 3 Qubits

Mean:
![Coefficiens 2D 3 Qubits - Mean](../docs/figures/coeff_mean_qubits3_2D_light.png)

Relative Standard Deviation:
![Coefficiens 2D 3 Qubits - Mean](../docs/figures/coeff_sd_qubits3_2D_light.png)

Covariance:
![Coefficiens 2D 3 Qubits - Mean](../docs/figures/coeff_covar_qubits3_2D_light.png)


#### 4 Qubits

Mean:
![Coefficiens 2D 4 Qubits - Mean](../docs/figures/coeff_mean_qubits4_2D_light.png)

Relative Standard Deviation:
![Coefficiens 2D 4 Qubits - Mean](../docs/figures/coeff_sd_qubits4_2D_light.png)

Covariance:
![Coefficiens 2D 4 Qubits - Mean](../docs/figures/coeff_covar_qubits4_2D_light.png)


#### 5 Qubits

Mean:
![Coefficiens 2D 5 Qubits - Mean](../docs/figures/coeff_mean_qubits5_2D_light.png)

Relative Standard Deviation:
![Coefficiens 2D 5 Qubits - Mean](../docs/figures/coeff_sd_qubits5_2D_light.png)

Covariance:
![Coefficiens 2D 5 Qubits - Mean](../docs/figures/coeff_covar_qubits5_2D_light.png)


#### 6 Qubits

Mean (Figure 7a in our paper):
![Coefficiens 2D 6 Qubits - Mean](../docs/figures/coeff_mean_qubits6_2D_light.png)

Relative Standard Deviation (Figure 7b in our paper):
![Coefficiens 2D 6 Qubits - Mean](../docs/figures/coeff_sd_qubits6_2D_light.png)

Covariance (Figure 5 in our paper):
![Coefficiens 2D 6 Qubits - Mean](../docs/figures/coeff_covar_qubits6_2D_light.png)


## Expressibility

Our Figure 10 in the paper:
![Expressibility](../docs/figures/expr_light.png)
(Expressibility (i.e. inverse of the KL-divergence) under the influence of increasing noise levels. The points represent the mean and the small shaded areas around it refer to the minimum and maximum across all five seeds.)


## Entanglement

Meyer-Wallach Entanglement for the pure states:
![Entanglement](../docs/figures/ent_mw_light.png)

Our Figure 11 in the paper:
![Entanglement](../docs/figures/ent_light.png)
(Meyer-Wallach (MW) entangling capability and Entanglement of Formation (EF) under the influence of increasing noise levels. Points represent the mean of five seeds and lines are a linear interpolation to guide the eye. Shaded areas present the minimum/maximum entanglement across the five seeds. As the difference between seeds is small, it is not visible in the plot.)
