# Results

On this page you can find links and explaination to supplementary results of our paper.
The same results, including dark-mode versions of the figures, are available on the [results website](https://cirkiters.github.io/effect-of-noise-in-qfms/).

Figure numbers refer to the current version of the manuscript.
In the plots, the ansätze are abbreviated as SEA (Strongly Entangling Ansatz), HEA (Hardware Efficient Ansatz), RYA (RY-Rotation-Only Ansatz, `Circuit_20` in the code) and CRA (Controlled Rotation Ansatz, `Circuit_19` in the code), and the noise types as BF (Bit Flip), PF (Phase Flip), DP (Depolarizing), SP (State Preparation), ME (Measurement), AD (Amplitude Damping), PD (Phase Damping) and CGE (Coherent Gate Error).

## Coefficients

The resulting plots of our experiments as PDF can be found in [this subdirectory](rplots/img-gen), while a PNG version can be found below.

### Input Encoding

Our Figure 2a from the paper:
![Coefficients Encoding Mean](../docs/figures/coeff_mean_encoding_light.png#only-light)
(Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies in the noiseless setting.)

And the corresponding relative standard deviation (Figure 11 in the paper):
![Coefficients Encoding Standard Deviation](../docs/figures/coeff_sd_encoding_light.png#only-light)
(Relative standard deviation $\sigma_c(\boldsymbol{\omega})$ for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies.)

The relative standard deviation increases with frequency for all encodings and ansätze. Since $\sigma_c(\boldsymbol{\omega})$ is normalised by the coefficient mean $\mu_c(\boldsymbol{\omega})$, this does not indicate a larger absolute spread: the absolute standard deviation decreases exponentially with the frequency index, but the mean decays faster, so the high-frequency coefficients vary more strongly across parameter samples relative to their magnitude. Furthermore, the relative standard deviation reached at the highest frequency grows with the number of qubits, whereas at a fixed frequency it decreases with the qubit count.

Our Figure 2b from the paper:
![Coefficients Encoding Real/Imag](../docs/figures/coeff_real_imag_encoding_light.png#only-light)
(Coefficients of six-qubit circuits, separated into real and imaginary parts for different single qubit Pauli-encodings. The RYA only exhibits an imaginary part for the $R_Y$ encoding, which is why the $R_Y$ encoding is used for the one-dimensional results in the main text.)

### Noise Influence on Spectrum

The absolute coefficient mean and relative standard deviation under each noise type for six-qubit circuits with $R_Y$ encoding are Figure 4 and Figure 12 in the paper, see the [1D Coefficients](#1d-coefficients) section below.
Decoherent gate errors (BF, PF, DP) contract the spectrum uniformly, SPAM and damping errors (SP, ME, AD, PD) leave the measured spectrum largely intact, and coherent gate errors (CGE) preserve the encoding-allowed frequencies with $\mu_c(\boldsymbol{\omega})$ and $\sigma_c(\boldsymbol{\omega})$ coinciding with their noiseless values.
The one exception is the constant term under AD, which is shifted towards positive values:

Our Figure 5 from the paper:
![Real coefficient for zero frequency under amplitude damping](../docs/figures/coeff_real_AD_qubits6_light.png#only-light)
(Real coefficient for $\boldsymbol{\omega} = \boldsymbol{0}$ in a noiseless setting and under 3% AD for circuits with six qubits.)

### Summary

Our Figure 14 in the paper summarises the coefficient mean $\mu_c(\boldsymbol{\omega})$ for 1D ($R_X$ and $R_Y$ encoding) and 2D ($R_X R_Y$ encoding) inputs and all qubits, only depicting the zero and maximum frequency-coefficient under DP, AD and CGE, shown here:
![Coefficients Mean Summary](../docs/figures/coeff_abs_mean_light.png#only-light)
(Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for the lowest frequency $\boldsymbol{\omega}=\boldsymbol{0}$ and highest frequency $\boldsymbol{\omega} = \boldsymbol{\omega}_\text{max}$ in the respective spectrum under the influence of varying noise levels. We considered the one-dimensional encodings $R_X$ and $R_Y$ ($D$ = 1), and a two-dimensional encoding $R_X R_Y$ ($D$ = 2). The y-axes for each facet row are equal throughout the respective $\boldsymbol{\omega}$, but differ in between.)

The corresponding relative standard deviation is (Figure 15 in the paper)
![Coefficients SD Summary](../docs/figures/coeff_abs_sd_light.png#only-light)
(Relative standard deviation $\sigma_c(\boldsymbol{\omega})$ for the absolute coefficient mean values from Figure 14.)

The detailed mean and standard deviations for varying qubit counts can be found in the corresponding sections on [1D-coefficients](#1d-coefficients) and [2D-coefficients](#2d-coefficients).

### 1D Coefficients

We show the coefficient mean $\mu_c(\boldsymbol{\omega})$, the corresponding relative standard deviation $\sigma_c(\boldsymbol{\omega})$ and the covariance of real and imaginary parts for the $R_Y$ and the $R_X$ encoding. For the six-qubit case with $R_Y$ encoding, these correspond to Figure 4, Figure 12 and Figure 13 of the paper. Shown here are the plots for all qubit numbers.

#### RY Encoding

#### 3 Qubits

Mean:
![Coefficients RY 3 Qubits - Mean](../docs/figures/coeff_mean_qubits3_RY_light.png#only-light)

Relative Standard Deviation:
![Coefficients RY 3 Qubits - Relative SD](../docs/figures/coeff_sd_qubits3_RY_light.png#only-light)

Covariance:
![Coefficients RY 3 Qubits - Covariance](../docs/figures/coeff_covar_qubits3_RY_light.png#only-light)

#### 4 Qubits

Mean:
![Coefficients RY 4 Qubits - Mean](../docs/figures/coeff_mean_qubits4_RY_light.png#only-light)

Relative Standard Deviation:
![Coefficients RY 4 Qubits - Relative SD](../docs/figures/coeff_sd_qubits4_RY_light.png#only-light)

Covariance:
![Coefficients RY 4 Qubits - Covariance](../docs/figures/coeff_covar_qubits4_RY_light.png#only-light)

#### 5 Qubits

Mean:
![Coefficients RY 5 Qubits - Mean](../docs/figures/coeff_mean_qubits5_RY_light.png#only-light)

Relative Standard Deviation:
![Coefficients RY 5 Qubits - Relative SD](../docs/figures/coeff_sd_qubits5_RY_light.png#only-light)

Covariance:
![Coefficients RY 5 Qubits - Covariance](../docs/figures/coeff_covar_qubits5_RY_light.png#only-light)

#### 6 Qubits

Mean:
![Coefficients RY 6 Qubits - Mean](../docs/figures/coeff_mean_qubits6_RY_light.png#only-light)

Relative Standard Deviation:
![Coefficients RY 6 Qubits - Relative SD](../docs/figures/coeff_sd_qubits6_RY_light.png#only-light)

Covariance:
![Coefficients RY 6 Qubits - Covariance](../docs/figures/coeff_covar_qubits6_RY_light.png#only-light)

Covariance -- selection of the frequencies $\boldsymbol{\omega} \in \{0, 1, \text{max}\}$ in the noiseless setting and under 3% of each noise type (Figure 13 in the paper):
![Coefficients RY 6 Qubits - Covariance selection](../docs/figures/coeff_covar_qubits6_sel_RY_light.png#only-light)

#### RX Encoding

#### 3 Qubits

Mean:
![Coefficients RX 3 Qubits - Mean](../docs/figures/coeff_mean_qubits3_RX_light.png#only-light)

Relative Standard Deviation:
![Coefficients RX 3 Qubits - Relative SD](../docs/figures/coeff_sd_qubits3_RX_light.png#only-light)

Covariance:
![Coefficients RX 3 Qubits - Covariance](../docs/figures/coeff_covar_qubits3_RX_light.png#only-light)

#### 4 Qubits

Mean:
![Coefficients RX 4 Qubits - Mean](../docs/figures/coeff_mean_qubits4_RX_light.png#only-light)

Relative Standard Deviation:
![Coefficients RX 4 Qubits - Relative SD](../docs/figures/coeff_sd_qubits4_RX_light.png#only-light)

Covariance:
![Coefficients RX 4 Qubits - Covariance](../docs/figures/coeff_covar_qubits4_RX_light.png#only-light)

#### 5 Qubits

Mean:
![Coefficients RX 5 Qubits - Mean](../docs/figures/coeff_mean_qubits5_RX_light.png#only-light)

Relative Standard Deviation:
![Coefficients RX 5 Qubits - Relative SD](../docs/figures/coeff_sd_qubits5_RX_light.png#only-light)

Covariance:
![Coefficients RX 5 Qubits - Covariance](../docs/figures/coeff_covar_qubits5_RX_light.png#only-light)

#### 6 Qubits

Mean:
![Coefficients RX 6 Qubits - Mean](../docs/figures/coeff_mean_qubits6_RX_light.png#only-light)

Relative Standard Deviation:
![Coefficients RX 6 Qubits - Relative SD](../docs/figures/coeff_sd_qubits6_RX_light.png#only-light)

Covariance:
![Coefficients RX 6 Qubits - Covariance](../docs/figures/coeff_covar_qubits6_RX_light.png#only-light)

Covariance -- selection of the frequencies $\boldsymbol{\omega} \in \{0, 1, \text{max}\}$ in the noiseless setting and under 3% of each noise type:
![Coefficients RX 6 Qubits - Covariance selection](../docs/figures/coeff_covar_qubits6_sel_RX_light.png#only-light)

### 2D Coefficients

Results for the two-dimensional encoding $R_X R_Y$ (two seeds). We denote the first frequency component as $\omega^{(1)}$ and the second as $\omega^{(2)}$.

#### 3 Qubits

Mean:
![Coefficients 2D 3 Qubits - Mean](../docs/figures/coeff_mean_qubits3_2D_light.png#only-light)

Relative Standard Deviation:
![Coefficients 2D 3 Qubits - Relative SD](../docs/figures/coeff_sd_qubits3_2D_light.png#only-light)

Covariance:
![Coefficients 2D 3 Qubits - Covariance](../docs/figures/coeff_covar_qubits3_2D_light.png#only-light)

#### 4 Qubits

Mean:
![Coefficients 2D 4 Qubits - Mean](../docs/figures/coeff_mean_qubits4_2D_light.png#only-light)

Relative Standard Deviation:
![Coefficients 2D 4 Qubits - Relative SD](../docs/figures/coeff_sd_qubits4_2D_light.png#only-light)

Covariance:
![Coefficients 2D 4 Qubits - Covariance](../docs/figures/coeff_covar_qubits4_2D_light.png#only-light)

#### 5 Qubits

Mean:
![Coefficients 2D 5 Qubits - Mean](../docs/figures/coeff_mean_qubits5_2D_light.png#only-light)

Relative Standard Deviation:
![Coefficients 2D 5 Qubits - Relative SD](../docs/figures/coeff_sd_qubits5_2D_light.png#only-light)

Covariance:
![Coefficients 2D 5 Qubits - Covariance](../docs/figures/coeff_covar_qubits5_2D_light.png#only-light)

#### 6 Qubits

Mean:
![Coefficients 2D 6 Qubits - Mean](../docs/figures/coeff_mean_qubits6_2D_light.png#only-light)

Relative Standard Deviation:
![Coefficients 2D 6 Qubits - Relative SD](../docs/figures/coeff_sd_qubits6_2D_light.png#only-light)

Covariance:
![Coefficients 2D 6 Qubits - Covariance](../docs/figures/coeff_covar_qubits6_2D_light.png#only-light)

## Training

Six-qubit QFMs with $R_Y$ encoding are trained on ten randomly generated Fourier series over ten parameter initialisation seeds for 1000 steps (Adam, learning rate 0.01) by minimising the squared complex coefficient error summed over all frequencies, which on the training grid is equivalent to the MSE. Noisy training uses a noise level of 3% for each noise type.

### Noiseless Training

Our Figure 3 in the paper:
![Noiseless training seed 1000](../docs/figures/training_noiseless_seed1000_light.png#only-light)
(Training performance in a noiseless setting for a single randomly generated problem instance (seed 1000). Lines represent the mean, and shaded areas show the standard deviation over ten parameter initialisation seeds. Left: the MSE during training. Right: the learned absolute coefficients; the coefficients of the objective Fourier series are marked with dashed lines.)

The same plots for the remaining problem instances:

Problem instance seed 1001:
![Noiseless training seed 1001](../docs/figures/training_noiseless_seed1001_light.png#only-light)

Problem instance seed 1002:
![Noiseless training seed 1002](../docs/figures/training_noiseless_seed1002_light.png#only-light)

Problem instance seed 1003:
![Noiseless training seed 1003](../docs/figures/training_noiseless_seed1003_light.png#only-light)

Problem instance seed 1004:
![Noiseless training seed 1004](../docs/figures/training_noiseless_seed1004_light.png#only-light)

Problem instance seed 1005:
![Noiseless training seed 1005](../docs/figures/training_noiseless_seed1005_light.png#only-light)

Problem instance seed 1006:
![Noiseless training seed 1006](../docs/figures/training_noiseless_seed1006_light.png#only-light)

Problem instance seed 1007:
![Noiseless training seed 1007](../docs/figures/training_noiseless_seed1007_light.png#only-light)

Problem instance seed 1008:
![Noiseless training seed 1008](../docs/figures/training_noiseless_seed1008_light.png#only-light)

Problem instance seed 1009:
![Noiseless training seed 1009](../docs/figures/training_noiseless_seed1009_light.png#only-light)

### Final Training Performance under Noise

Our Figure 6 in the paper:
![Final training performance](../docs/figures/training_coeff_dist_final_light.png#only-light)
(Training performance after 1000 training steps in the noiseless setting and under each noise type (3%), averaged over ten model parameter initialisation seeds and ten randomly generated problem instances. Bars represent the mean and error bars the standard deviation over the 10 × 10 configurations. Left: final MSE for each ansatz (rows) and noise type. Right: final squared coefficient error $\Delta c_{\boldsymbol{\omega}} = \lvert c_{\boldsymbol{\omega}}(\boldsymbol{\theta}) - c'_{\boldsymbol{\omega}} \rvert^2$ for each frequency $\boldsymbol{\omega}$.)

### Training Curves

Our Figure 17 in the paper:
![Training MSE](../docs/figures/training_mse_light.png#only-light)
(The MSE over ten parameter initialisation seeds and ten randomly generated problem instances during training in the noiseless setting and under each noise type (3%). Lines represent the mean, and shaded areas show the standard deviation over the 10 × 10 configurations.)

Our Figure 18 in the paper:
![Training Coefficient Difference](../docs/figures/training_coeff_dist_light.png#only-light)
(The squared coefficient error $\Delta c_{\boldsymbol{\omega}}$ averaged over ten model parameter initialisation seeds and ten randomly generated problem instances during training in the noiseless setting and under each noise type (3%). Lines represent the mean, and shaded areas show the standard deviation over the 10 × 10 configurations.)

### Coefficients during Training for Problem Instances

The learned absolute coefficients averaged over ten model parameter initialisation seeds for each single randomly generated problem instance with seeds $[1000\dots 1009]$ and different types of noise (3%) during training of 1000 steps. Shaded areas correspond to the standard deviation across the parameter initialisation seeds from the mean. The coefficients of the objective Fourier series are marked with dashed lines.

Problem instance seed 1000 (Figure 19 in the paper):
![Training Coefficients seed 1000](../docs/figures/training_coeffs_seed1000_light.png#only-light)

Problem instance seed 1001:
![Training Coefficients seed 1001](../docs/figures/training_coeffs_seed1001_light.png#only-light)

Problem instance seed 1002:
![Training Coefficients seed 1002](../docs/figures/training_coeffs_seed1002_light.png#only-light)

Problem instance seed 1003:
![Training Coefficients seed 1003](../docs/figures/training_coeffs_seed1003_light.png#only-light)

Problem instance seed 1004:
![Training Coefficients seed 1004](../docs/figures/training_coeffs_seed1004_light.png#only-light)

Problem instance seed 1005:
![Training Coefficients seed 1005](../docs/figures/training_coeffs_seed1005_light.png#only-light)

Problem instance seed 1006:
![Training Coefficients seed 1006](../docs/figures/training_coeffs_seed1006_light.png#only-light)

Problem instance seed 1007:
![Training Coefficients seed 1007](../docs/figures/training_coeffs_seed1007_light.png#only-light)

Problem instance seed 1008:
![Training Coefficients seed 1008](../docs/figures/training_coeffs_seed1008_light.png#only-light)

Problem instance seed 1009:
![Training Coefficients seed 1009](../docs/figures/training_coeffs_seed1009_light.png#only-light)

### Entanglement during Training

Our Figure 20 in the paper:
![Entanglement during training](../docs/figures/training_ent_light.png#only-light)
(Entangling capability, measured by the mean negativity $\overline{\mathcal{N}}$ during training. Lines represent the mean over ten parameter initialisation seeds and ten problem generation seeds. Shaded areas represent the standard deviation.)

## Expressibility

Our Figure 7 in the paper:
![Expressibility](../docs/figures/expr_light.png#only-light)
(Kullback-Leibler (KL) divergence of the fidelity distribution from the Haar reference under increasing noise levels, with lower values indicating higher expressibility. Points represent the mean over the five seeds. The dotted lines mark the upper bound $(2^n-1)\ln(75n)$ for each qubit count and hence the least expressive case.)

Our Figure 16 in the paper:
![Expressibility for deeper circuits](../docs/figures/expr_layers_light.png#only-light)
(KL divergence for $L \in \{1, 2, 4\}$ encoding layers at a fixed noise level of 3% for each noise type. The first column shows the noiseless reference. Points represent the mean over the five seeds, and the dotted lines mark the upper bound of the KL divergence for each qubit count. The values for $L = 1$ correspond to the 3% points in Figure 7.)

## Entanglement

Our Figure 8 in the paper:
![Entanglement noiseless](../docs/figures/ent_noiseless_light.png#only-light)
(Entangling capability, measured by the mean negativity $\overline{\mathcal{N}}$ averaged over randomly sampled parameters, for the considered ansätze in a noiseless environment. The bars represent the mean values with error bars from the minimum to maximum highlighted in red across the five seeds.)

Our Figure 9 in the paper:
![Entanglement](../docs/figures/ent_light.png#only-light)
(Entangling capability, measured by the mean negativity $\overline{\mathcal{N}}$ averaged over randomly sampled parameters, under the influence of increasing noise levels. Points represent the mean of five seeds and lines are a linear interpolation to guide the eye. The zero-noise points correspond to the values in Figure 8.)
