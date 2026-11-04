# Coefficients

The resulting plots of our experiments as PDF can be found in [plotting/rplots/img-gen](https://github.com/cirKITers/effect-of-noise-in-qfms/tree/main/plotting/rplots/img-gen), while a PNG version can be found on this website.

We characterise the Fourier coefficients of a QFM by sampling the trainable parameters and computing the absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ and the relative standard deviation $\sigma_c(\boldsymbol{\omega})$ (normalised by $\mu_c(\boldsymbol{\omega})$) for each frequency $\boldsymbol{\omega}$ via the FFT.
All plots show the mean over the seeds, as the standard deviation across seeds is small.
In the plots, the ansätze are abbreviated as SEA (Strongly Entangling Ansatz), HEA (Hardware Efficient Ansatz), RYA (RY-Rotation-Only Ansatz) and CRA (Controlled Rotation Ansatz), and the noise types as BF (Bit Flip), PF (Phase Flip), DP (Depolarizing), SP (State Preparation), ME (Measurement), AD (Amplitude Damping), PD (Phase Damping) and CGE (Coherent Gate Error), see [Setup](setup.md).

## Influence of Input Encoding

We measure the coefficients for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies in a noiseless setting.

Our Figure 2a from the paper:
![Coefficients Encoding Mean](figures/coeff_mean_encoding_light.png#only-light)
![Coefficients Encoding Mean](figures/coeff_mean_encoding_dark.png#only-dark)

Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ over frequencies for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings in the noiseless setting.

The absolute coefficient mean decreases with the frequency for all ansätze and encodings.
Only the SEA and the CRA consistently provide the full spectrum, and only the SEA does so with coefficients that remain of comparable magnitude across frequencies, while the HEA does not reach the highest frequencies for larger qubit counts (an absolute coefficient mean below $10^{-14}$ is treated as numerically zero).

The corresponding relative standard deviation (Our Figure 11 in the paper, Appendix "Relative Standard Deviation of the Coefficients"):
![Coefficients Encoding Standard Deviation](figures/coeff_sd_encoding_light.png#only-light)
![Coefficients Encoding Standard Deviation](figures/coeff_sd_encoding_dark.png#only-dark)

Relative standard deviation $\sigma_c(\boldsymbol{\omega})$ of the coefficients for $[3\dots 6]$ qubits and $R_{\{X, Y, Z\}}$ encodings over frequencies in the noiseless setting, corresponding to the absolute coefficient mean in Fig. 2a.

In contrast to the mean, the relative standard deviation increases with frequency for all encodings and ansätze. Since $\sigma_c(\boldsymbol{\omega})$ is normalised by the absolute coefficient mean $\mu_c(\boldsymbol{\omega})$, this does not indicate a larger absolute spread: the absolute standard deviation of the coefficients decreases exponentially with the frequency index, but the mean decays faster, so high-frequency coefficients vary more strongly across parameter samples relative to their magnitude. Furthermore, the relative standard deviation reached at the highest frequency grows with the number of qubits, whereas at a fixed frequency it decreases with the qubit count.

Our Figure 2b from the paper:
![Coefficients Encoding Real/Imag](figures/coeff_real_imag_encoding_light.png#only-light)
![Coefficients Encoding Real/Imag](figures/coeff_real_imag_encoding_dark.png#only-dark)

Coefficients of six-qubit circuits, separated into real and imaginary parts for different single qubit Pauli-encodings. The individual frequency components are colour-coded.

While there is no obvious difference in $\mu_c(\boldsymbol{\omega})$ between the encodings, the RYA only exhibits an imaginary part in the coefficients for the $R_Y$ encoding: with $R_X$ or $R_Z$ encoding, all gates, the initial state and the $Z$ readout are real up to the conjugation symmetry $R_X(x)^* = R_X(-x)$ and $R_Z(x)^* = R_Z(-x)$, such that $f(-x, \boldsymbol{\theta}) = f(x, \boldsymbol{\theta})$ and the coefficients are real. Therefore, the $R_Y$ encoding is used for the one-dimensional results in the main text of the paper.
Apart from this exception, the coefficients are evenly distributed in the real and imaginary part with no clear correlation, which is corroborated by the covariance plots on the [coefficients RX](coefficients1d_rx.md), [coefficients RY](coefficients1d_ry.md) and [2D-coefficients](coefficients2d.md) pages.

## Noise Influence on Spectrum

The absolute coefficient mean and the relative standard deviation under each noise type for six-qubit circuits with $R_Y$ encoding are shown as Figure 4 and Figure 12 in the paper; both are shown on the [coefficients RY](coefficients1d_ry.md) page, together with the results for three to five qubits.
The noise types fall into three regimes with qualitatively different effects on the spectrum:

- **Decoherent gate errors (BF, PF, DP) contract the spectrum uniformly.** The absolute coefficient mean decays exponentially with the noise level, at the same rate for all frequencies, such that the shape of the spectrum is preserved while its magnitude shrinks. The relative standard deviation remains constant, so the absolute variance contracts with $\mu_c(\boldsymbol{\omega})^2$.
- **SPAM and damping errors (SP, ME, AD, PD) leave the measured spectrum largely intact.** As they act only once per qubit at the circuit boundary, their effect on the coefficient magnitudes is small. Terminal PD preserves the $Z$ expectation values exactly, ME multiplies all coefficients by $1 - 2p$, and AD multiplies the nonzero-frequency coefficients by $1 - p$ while shifting the constant term to $(1-p)c_{\boldsymbol{0}} + p$, i.e. towards positive values, as shown below.
- **Coherent gate errors (CGE) preserve the encoding-allowed frequencies.** For a fixed realisation of the additive offsets, the frequency set is unchanged, and $\mu_c(\boldsymbol{\omega})$ and $\sigma_c(\boldsymbol{\omega})$ coincide with their noiseless values at every tested level for all ansätze, as the fixed offsets are absorbed into the uniformly sampled trainable angles.

Our Figure 5 in the paper:
![Real coefficient for zero frequency under amplitude damping](figures/coeff_real_AD_qubits6_light.png#only-light)
![Real coefficient for zero frequency under amplitude damping](figures/coeff_real_AD_qubits6_dark.png#only-dark)

Real coefficient for $\boldsymbol{\omega} = \boldsymbol{0}$ in a noiseless setting and under 3% Amplitude Damping (AD) for circuits with six qubits and $R_Y$ encoding.

## Summary across Encodings and Qubit Counts

Our Figure 14 in the paper (Appendix "Quantitative Coefficient Results") summarises the coefficient mean $\mu_c(\boldsymbol{\omega})$ for 1D ($R_X$ and $R_Y$ encoding) and 2D ($R_X R_Y$ encoding) inputs and all qubit counts, only depicting the zero and maximum frequency-coefficient under DP, AD and CGE as representatives of the three noise regimes:
![Coefficients Mean Summary](figures/coeff_abs_mean_light.png#only-light)
![Coefficients Mean Summary](figures/coeff_abs_mean_dark.png#center#only-dark)

Absolute coefficient mean $\mu_c(\boldsymbol{\omega})$ for the lowest frequency $\boldsymbol{\omega}=\boldsymbol{0}$ and highest frequency $\boldsymbol{\omega} = \boldsymbol{\omega}_\text{max}$ in the respective spectrum under the influence of varying noise levels. We considered the one-dimensional encodings $R_X$ and $R_Y$ ($D$ = 1), and a two-dimensional encoding $R_X R_Y$ ($D$ = 2). The y-axes for each facet row are equal throughout the respective $\boldsymbol{\omega}$, but differ in between.

The corresponding relative standard deviation is (Our Figure 15 in the paper)
![Coefficients SD Summary](figures/coeff_abs_sd_light.png#only-light)
![Coefficients SD Summary](figures/coeff_abs_sd_dark.png#only-dark)

Relative standard deviation $\sigma_c(\boldsymbol{\omega})$ for the absolute coefficient mean values from Fig. 14.

DP causes an exponential decline of $\mu_c(\boldsymbol{\omega})$ for both coefficient classes, all qubit counts, encodings and ansätze, which is steeper for larger qubit counts and the two-dimensional encoding, while $\sigma_c(\boldsymbol{\omega})$ remains approximately constant.
AD increases $\mu_c(\boldsymbol{0})$ and decreases $\sigma_c(\boldsymbol{0})$ following the affine shift of the constant term, most evidently for the SEA, and has an imperceptible effect at $\boldsymbol{\omega}_\text{max}$.
Under CGE, both quantities coincide with their noiseless values.

The detailed mean, standard deviations and covariances for varying qubit counts and encodings can be found in the corresponding pages on [coefficients RX](coefficients1d_rx.md), [coefficients RY](coefficients1d_ry.md) and [2D-coefficients](coefficients2d.md).
