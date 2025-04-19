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

## Ansaetze

We use the following ansaetze throughout our experiments:

### Strongly Entangling
![Strongly Entangling](figures/Strongly_Entangling_light.png#circuit#only-light)
![Strongly Entangling](figures/Strongly_Entangling_dark.png#circuit#only-dark)

### Hardware Efficient
![Hardware Efficient](figures/Hardware_Efficient_light.png#circuit#only-light)
![Hardware Efficient](figures/Hardware_Efficient_dark.png#circuit#only-dark)

### Circuit 15
![Circuit 15](figures/Circuit_15_light.png#circuit#only-light)
![Circuit 15](figures/Circuit_15_dark.png#circuit#only-dark)

### Circuit 19
![Circuit 19](figures/Circuit_19_light.png#circuit#only-light)
![Circuit 19](figures/Circuit_19_dark.png#circuit#only-dark)