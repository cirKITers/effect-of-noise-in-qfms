# Training

We train six-qubit QFMs with $R_Y$ encoding on randomly generated Fourier series (see [Setup](setup.md)) by minimising the squared complex coefficient error summed over all frequencies with Adam (learning rate 0.01) for 1000 steps.
During training we record the mean squared error (MSE), the learned absolute coefficients $\lvert c_{\boldsymbol{\omega}} \rvert$, the squared coefficient error $\Delta c_{\boldsymbol{\omega}} = \lvert c_{\boldsymbol{\omega}}(\boldsymbol{\theta}) - c'_{\boldsymbol{\omega}} \rvert^2$ between the learned and the target coefficients and the entangling capability.
As the training grid samples one period without aliasing, Parseval's identity relates the two error metrics via $\text{MSE} = \sum_{\boldsymbol{\omega}} \Delta c_{\boldsymbol{\omega}}$.
Noisy training uses a noise level of 3% for each noise type.
The abbreviations of the ansätze and noise types are explained on the [Setup](setup.md) page.

## Noiseless Training

Our Figure 3 in the paper:
![Noiseless training seed 1000](figures/training_noiseless_seed1000_light.png#only-light)
![Noiseless training seed 1000](figures/training_noiseless_seed1000_dark.png#only-dark)

Training performance in a noiseless setting for a single randomly generated problem instance (seed 1000) during training of 1000 steps. Lines represent the mean, and shaded areas show the standard deviation over ten parameter initialisation seeds. Left: The MSE during training. Right: The learned absolute coefficients of the QFMs. The coefficients of the objective Fourier series are marked with dashed lines.

For this problem instance, the HEA and CRA retain larger errors, while the RYA and the SEA achieve lower MSEs, with the SEA performing best.
Across all ansätze, most of the learned coefficients that correspond to lower frequencies converge to the targets, whereas the ansätze that converge to a higher MSE especially fail to match higher-frequency coefficients.
Frequency availability alone therefore does not guarantee a match to the target coefficients within the fixed optimisation budget, even without noise.

The same plots for the remaining problem instances with seeds $[1001\dots 1009]$:

Problem instance seed 1001:
![Noiseless training seed 1001](figures/training_noiseless_seed1001_light.png#only-light)
![Noiseless training seed 1001](figures/training_noiseless_seed1001_dark.png#only-dark)

Problem instance seed 1002:
![Noiseless training seed 1002](figures/training_noiseless_seed1002_light.png#only-light)
![Noiseless training seed 1002](figures/training_noiseless_seed1002_dark.png#only-dark)

Problem instance seed 1003:
![Noiseless training seed 1003](figures/training_noiseless_seed1003_light.png#only-light)
![Noiseless training seed 1003](figures/training_noiseless_seed1003_dark.png#only-dark)

Problem instance seed 1004:
![Noiseless training seed 1004](figures/training_noiseless_seed1004_light.png#only-light)
![Noiseless training seed 1004](figures/training_noiseless_seed1004_dark.png#only-dark)

Problem instance seed 1005:
![Noiseless training seed 1005](figures/training_noiseless_seed1005_light.png#only-light)
![Noiseless training seed 1005](figures/training_noiseless_seed1005_dark.png#only-dark)

Problem instance seed 1006:
![Noiseless training seed 1006](figures/training_noiseless_seed1006_light.png#only-light)
![Noiseless training seed 1006](figures/training_noiseless_seed1006_dark.png#only-dark)

Problem instance seed 1007:
![Noiseless training seed 1007](figures/training_noiseless_seed1007_light.png#only-light)
![Noiseless training seed 1007](figures/training_noiseless_seed1007_dark.png#only-dark)

Problem instance seed 1008:
![Noiseless training seed 1008](figures/training_noiseless_seed1008_light.png#only-light)
![Noiseless training seed 1008](figures/training_noiseless_seed1008_dark.png#only-dark)

Problem instance seed 1009:
![Noiseless training seed 1009](figures/training_noiseless_seed1009_light.png#only-light)
![Noiseless training seed 1009](figures/training_noiseless_seed1009_dark.png#only-dark)

## Final Training Performance under Noise

Our Figure 6 in the paper:
![Final training performance](figures/training_coeff_dist_final_light.png#only-light)
![Final training performance](figures/training_coeff_dist_final_dark.png#only-dark)

Training performance after 1000 training steps in the noiseless setting and under each noise type (3%), averaged over ten model parameter initialisation seeds and ten randomly generated problem instances. Bars represent the mean and error bars the standard deviation over the 10 × 10 configurations. Left: final MSE for each ansatz (rows) and noise type. Right: final squared coefficient error $\Delta c_{\boldsymbol{\omega}}$ between the learned coefficients $c_{\boldsymbol{\omega}}(\boldsymbol{\theta})$ and the target coefficients $c'_{\boldsymbol{\omega}}$ for each frequency $\boldsymbol{\omega}$.

Decoherent gate errors raise the MSE to a similar level of approximately 0.02 for all ansätze, with DP typically being the most harmful, whereas SPAM and damping errors leave the MSE at its noiseless level.
Consequently, the SEA, which achieves the lowest noiseless fitting errors, loses much of this advantage under decoherent gate errors.
For fixed coherent gate errors, the final MSE and the coefficient errors coincide with the noiseless values for every ansatz, as the fixed offsets are compensated during training.
Decoherent gate errors increase $\Delta c_{\boldsymbol{\omega}}$ predominantly for the higher frequencies, in line with the contraction of the coefficients observed on the [Coefficients](coefficients.md) page: the optimiser counteracts the contraction for the low-frequency coefficients but leaves larger residuals at high frequencies.
The frequencies with numerically vanishing absolute coefficient means in the noiseless HEA retain a constant error regardless of the noise type, and the higher-frequency coefficients of the RYA and the CRA are not matched even without noise.

## Mean Squared Error

Our Figure 17 in the paper (Appendix "Training Curves"):
![Training MSE](figures/training_mse_light.png#only-light)
![Training MSE](figures/training_mse_dark.png#only-dark)

The MSE over ten parameter initialisation seeds and ten randomly generated problem instances during training in the noiseless setting and under each noise type (3%). Lines represent the mean, and shaded areas show the standard deviation over the 10 × 10 configurations.

## Squared Coefficient Error

Our Figure 18 in the paper:
![Training Coefficient Difference](figures/training_coeff_dist_light.png#only-light)
![Training Coefficient Difference](figures/training_coeff_dist_dark.png#only-dark)

The squared coefficient error $\Delta c_{\boldsymbol{\omega}}$ averaged over ten model parameter initialisation seeds and ten randomly generated problem instances during training in the noiseless setting and under each noise type (3%). Lines represent the mean, and shaded areas show the standard deviation over the 10 × 10 configurations.

All configurations reach a plateau before the end of the training, such that the final values in Fig. 6 reflect the attainable level of each configuration.
Lower frequencies are matched within the first few hundred steps, whereas higher frequencies converge more slowly.

## Coefficients during Training for Problem Instances

In the following, we show the learned absolute coefficients of the QFMs averaged over ten parameter model initialisation seeds for each single randomly generated problem instance with seeds $[1000\dots 1009]$ and different types of noise (3%) during training of 1000 steps. In the figures the shaded areas correspond to the standard deviation across the parameter initialisation seeds from the mean. The coefficients of the objective Fourier series are marked with dashed lines.
Under decoherent gate errors, the low-frequency coefficients still converge to their targets, whereas the high-frequency coefficients saturate below their targets, such that the learned spectrum is tilted towards the low frequencies relative to the target.
Since the coherent gate errors are quasi-static, the offsets remain fixed across training steps and the curves are indistinguishable from the noiseless ones.

Problem instance seed 1000 (Our Figure 19 in the paper):
![Training Coefficients seed 1000](figures/training_coeffs_seed1000_light.png#only-light)
![Training Coefficients seed 1000](figures/training_coeffs_seed1000_dark.png#only-dark)

Problem instance seed 1001:
![Training Coefficients seed 1001](figures/training_coeffs_seed1001_light.png#only-light)
![Training Coefficients seed 1001](figures/training_coeffs_seed1001_dark.png#only-dark)

Problem instance seed 1002:
![Training Coefficients seed 1002](figures/training_coeffs_seed1002_light.png#only-light)
![Training Coefficients seed 1002](figures/training_coeffs_seed1002_dark.png#only-dark)

Problem instance seed 1003:
![Training Coefficients seed 1003](figures/training_coeffs_seed1003_light.png#only-light)
![Training Coefficients seed 1003](figures/training_coeffs_seed1003_dark.png#only-dark)

Problem instance seed 1004:
![Training Coefficients seed 1004](figures/training_coeffs_seed1004_light.png#only-light)
![Training Coefficients seed 1004](figures/training_coeffs_seed1004_dark.png#only-dark)

Problem instance seed 1005:
![Training Coefficients seed 1005](figures/training_coeffs_seed1005_light.png#only-light)
![Training Coefficients seed 1005](figures/training_coeffs_seed1005_dark.png#only-dark)

Problem instance seed 1006:
![Training Coefficients seed 1006](figures/training_coeffs_seed1006_light.png#only-light)
![Training Coefficients seed 1006](figures/training_coeffs_seed1006_dark.png#only-dark)

Problem instance seed 1007:
![Training Coefficients seed 1007](figures/training_coeffs_seed1007_light.png#only-light)
![Training Coefficients seed 1007](figures/training_coeffs_seed1007_dark.png#only-dark)

Problem instance seed 1008:
![Training Coefficients seed 1008](figures/training_coeffs_seed1008_light.png#only-light)
![Training Coefficients seed 1008](figures/training_coeffs_seed1008_dark.png#only-dark)

Problem instance seed 1009:
![Training Coefficients seed 1009](figures/training_coeffs_seed1009_light.png#only-light)
![Training Coefficients seed 1009](figures/training_coeffs_seed1009_dark.png#only-dark)

## Entanglement during Training

Our Figure 20 in the paper (Appendix "Entanglement during Training"):
![Entanglement during training](figures/training_ent_light.png#only-light)
![Entanglement during training](figures/training_ent_dark.png#only-dark)

Entangling capability, measured by the mean negativity $\overline{\mathcal{N}}$ (see [Entanglement](entanglement.md)) during training. Lines represent the mean over ten parameter initialisation seeds and ten problem generation seeds. Shaded areas represent the standard deviation.

The orders of magnitude of the entangling capability under the different noise types are similar to those measured for randomly sampled parameters.
Over the course of the training we observe a decrease in the entangling capability for most configurations (with the exception of damping errors), which is more pronounced in some experiments (e.g. SEA with DP) but consistent across all tested problem and model initialisation seeds for each configuration.
The similar mean negativities of the SEA, HEA and RYA accompany different MSEs, so this zero-input descriptor alone does not determine fitting performance on the tested tasks.
