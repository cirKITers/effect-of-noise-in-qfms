# Training

## Mean Squared Error

Our Figure 9 in the paper:
![Training MSE](figures/training_mse_light.png#only-light)
![Training MSE](figures/training_mse_dark.png#only-dark)

The Mean Squared Error (MSE) over ten parameter initialisation seeds and ten randomly generated problem instances during training. Lines represent the mean, and shaded areas show the standard deviation over the 10 × 10 configurations.

## Coefficient Difference
Our Figure 10 in the paper:
![Training Coefficient Difference](figures/training_coeff_dist_light.png#only-light)
![Training Coefficient Difference](figures/training_coeff_dist_dark.png#only-dark)

The difference $\Delta_{c_{\boldsymbol{\omega}}}$ between the target and learned coefficients $c_{\boldsymbol{\omega}}(\boldsymbol{\theta})$ and $c'_{\boldsymbol{\omega}}$ respectively of the QFMs averaged over ten model parameter initialisation seeds and ten randomly generated problem instances during training. Lines represent the mean, and shaded areas show the standard deviation over the 10 × 10 configurations.

## Coefficients during Training for Problem Instances

In the following, we show the learned absolute coefficients of the QFMs averaged over ten parameter model initialisation seeds for each single randomly generated probelm instance with seeds $[1000\dots 1009]$ and different types of noise (3%) during training of 1000 steps. In the figures the shaded areas correspond to the standard deviation across the parameter initialisation seeds from the mean. The coefficients of the objective Fourier series are marked with dashed lines.

Problem instance seed 1000 (Our Figure 18 in the paper):
![Training Coefficients seed 1000](figures/training_coeffs_seed1000_light.png#only-light)
![Training Coefficients seed 1000](figures/training_coeffs_seed1000_dark.png#only-dark)

Problem instance seed 1001 (Our Figure 18 in the paper):
![Training Coefficients seed 1001](figures/training_coeffs_seed1001_light.png#only-light)
![Training Coefficients seed 1001](figures/training_coeffs_seed1001_dark.png#only-dark)

Problem instance seed 1002 (Our Figure 18 in the paper):
![Training Coefficients seed 1002](figures/training_coeffs_seed1002_light.png#only-light)
![Training Coefficients seed 1002](figures/training_coeffs_seed1002_dark.png#only-dark)

Problem instance seed 1003 (Our Figure 18 in the paper):
![Training Coefficients seed 1003](figures/training_coeffs_seed1003_light.png#only-light)
![Training Coefficients seed 1003](figures/training_coeffs_seed1003_dark.png#only-dark)

Problem instance seed 1004 (Our Figure 18 in the paper):
![Training Coefficients seed 1004](figures/training_coeffs_seed1004_light.png#only-light)
![Training Coefficients seed 1004](figures/training_coeffs_seed1004_dark.png#only-dark)

Problem instance seed 1005 (Our Figure 18 in the paper):
![Training Coefficients seed 1005](figures/training_coeffs_seed1005_light.png#only-light)
![Training Coefficients seed 1005](figures/training_coeffs_seed1005_dark.png#only-dark)

Problem instance seed 1006 (Our Figure 18 in the paper):
![Training Coefficients seed 1006](figures/training_coeffs_seed1006_light.png#only-light)
![Training Coefficients seed 1006](figures/training_coeffs_seed1006_dark.png#only-dark)

Problem instance seed 1007 (Our Figure 18 in the paper):
![Training Coefficients seed 1007](figures/training_coeffs_seed1007_light.png#only-light)
![Training Coefficients seed 1007](figures/training_coeffs_seed1007_dark.png#only-dark)

Problem instance seed 1008 (Our Figure 18 in the paper):
![Training Coefficients seed 1008](figures/training_coeffs_seed1008_light.png#only-light)
![Training Coefficients seed 1008](figures/training_coeffs_seed1008_dark.png#only-dark)

Problem instance seed 1009 (Our Figure 18 in the paper):
![Training Coefficients seed 1009](figures/training_coeffs_seed1009_light.png#only-light)
![Training Coefficients seed 1009](figures/training_coeffs_seed1009_dark.png#only-dark)

## Entanglement during Training

Our Figure 19 in the paper:
![Entanglement during training](figures/training_ent_light.png#only-light)
![Entanglement during training](figures/training_ent_dark.png#only-dark)

Entangling capability, assessed with the Meyer-Wallach measure for pure states (noiseless and coherent gate errors) and entanglement of formation for mixed states (decoherent-, SPAM- and damping errors) during training. Lines represent the mean over ten parameter initialisation seeds and ten problem generation seeds. Shaded areas represent the standard deviation.
