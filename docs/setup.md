# Setup

Our implementation heavily relies on our [QML Essentials package](https://cirkiters.github.io/qml-essentials/).
Furthermore we use [Kedro](https://kedro.readthedocs.io/) to manage our experiments.

## Noise Models

The noise model we use in our experiments can be summarized as follows:
![Noise Model](figures/noise_0_light.png#only-light)
![Noise Model](figures/noise_0_dark.png#only-dark)

Here, $\mathcal{N}_{SP}$ describes state preparation noise, $\mathcal{N}_{G}$ gate noise and $\mathcal{N}_{D}$ circuit noise.
Coherent gate errors are modelled by $\epsilon$.

The gate noise $\mathcal{N}_G$ can be decomposed as follows:
![Gate Noise](figures/noise_1_light.png#only-light)
![Gate Noise](figures/noise_1_dark.png#only-dark)

At the end of the circuit the noise model $\mathcal{N}_D$ is applied:
![Circuit Noise](figures/noise_2_light.png#only-light)
![Circuit Noise](figures/noise_2_dark.png#only-dark)

The noise types fall into four groups, which differ in where and how often a channel acts during one circuit evaluation (Table 1 in the paper):

| Group | Noise types | Placement | Applications |
| --- | --- | --- | --- |
| Decoherent gate errors | Bit Flip (BF), Phase Flip (PF), Depolarizing (DP) | after every gate | $N_g$ (number of local gate-noise insertions) |
| Damping errors | Amplitude Damping (AD), Phase Damping (PD) | once per qubit at the end of the circuit | $n$ |
| State preparation and measurement (SPAM) errors | State Preparation (SP), Measurement (ME) | once per qubit at the beginning / end of the circuit | $n$ |
| Coherent gate errors (CGE) | additive rotation-angle offsets $\epsilon \sim \mathcal{N}(0, p_\text{cge}^2)$ | every parametrised rotation | $N_r$ (number of rotation angles) |

Channel probabilities $p$ are specified per application, whereas $p_\text{cge}$ is the standard deviation of the additive angle error in radians.
Gate noise acts separately on each wire of a gate, so equal local probabilities do not imply equal accumulated noise across ansätze.
For the coefficient and training experiments, one realisation of the coherent offsets per circuit layout is kept fixed across inputs, parameter samples, optimisation steps and seeds, and the same standardised offsets are scaled with $p_\text{cge}$ across noise levels.
The expressibility and entanglement experiments instead sample the coherent offsets across the state batch.

## Ansaetze

We use the following ansaetze throughout our experiments (Figure 10 in the paper, shown for four qubits).
In the plots, the ansätze are abbreviated as SEA, HEA, RYA and CRA.
The RYA and CRA are inspired by circuits 15 and 19 of Sim et al. (2019) and are called `Circuit_20` and `Circuit_19` in the code and in the result data, respectively.

### Strongly Entangling Ansatz (SEA)
![Strongly Entangling](figures/Strongly_Entangling_light.png#circuit#only-light)
![Strongly Entangling](figures/Strongly_Entangling_dark.png#circuit#only-dark)

### Hardware Efficient Ansatz (HEA)
![Hardware Efficient](figures/Hardware_Efficient_light.png#circuit#only-light)
![Hardware Efficient](figures/Hardware_Efficient_dark.png#circuit#only-dark)

### RY-Rotation-Only Ansatz (RYA, Circuit 20)
![Circuit 20](figures/Circuit_20_light.png#circuit#only-light)
![Circuit 20](figures/Circuit_20_dark.png#circuit#only-dark)

### Controlled Rotation Ansatz (CRA, Circuit 19)
![Circuit 19](figures/Circuit_19_light.png#circuit#only-light)
![Circuit 19](figures/Circuit_19_dark.png#circuit#only-dark)

## Experimental Protocol

Unless stated otherwise, experiments use a single encoding layer ($L = 1$), $n \in [3\dots 6]$ qubits and the mean of the local $Z$ expectation values as readout.
The [deeper-circuit expressibility study](expressibility.md#expressibility_of_deeper_circuits) additionally tests $L = 2$ and $L = 4$ at a fixed noise level of 3% and without noise.
The main noise sweeps use seven linearly increasing levels from 0% to 3% in steps of 0.5%.
Trainable parameters are sampled uniformly from $[0, 2\pi]$ with five seeds for the one-dimensional coefficient, expressibility and entanglement experiments, two for the two-dimensional coefficient experiments and ten for the training experiments.

- **Coefficients:** one-dimensional ($R_X$, $R_Y$ or $R_Z$ encoding, $D = 1$) and two-dimensional ($R_X R_Y$ encoding, $D = 2$) inputs; $250 \times 2^n$ parameter vectors per seed for $D = 1$ and 250 per seed for $D = 2$. The two-dimensional experiments use two seeds.
- **Expressibility and entanglement** are evaluated on the density matrix at $\boldsymbol{x} = \boldsymbol{0}$, as these descriptors only depend on the trainable layers.
  Entanglement uses $250 \times 2^n$ parameter vectors per seed, while expressibility uses two independent batches of that size to form $250 \times 2^n$ state pairs and $75 n$ equal-width fidelity bins.
- **Training** uses six-qubit circuits with $R_Y$ encoding on ten randomly generated Fourier series with the same frequency set as the model and a maximum absolute target value of $a = 0.5$, using Adam (learning rate 0.01) for 1000 steps.
  The loss is the squared complex coefficient error summed over all frequencies, which equals the mean squared error (MSE) on an exact-period grid and approximates it on the configured training grid (see [Training](training.md)).
  Noisy training uses a noise level of 3% for each noise type.
