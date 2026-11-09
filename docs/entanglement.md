# Entanglement

We quantify the entangling capability with the *mean negativity*
$\overline{\mathcal{N}}(\rho) = \frac{2}{n}\sum_{k=0}^{n-1} \mathcal{N}_k(\rho) \in [0, 1]$,
where $\mathcal{N}_k(\rho)$ is the negativity of the bipartition of qubit $k$ versus the remaining qubits, i.e. the absolute sum of the negative eigenvalues of the partial transpose $\rho^{T_k}$.
In contrast to the Meyer-Wallach measure, the negativity is defined for pure and mixed states alike, such that the noiseless and the noisy experiments use the same measure.
The entangling capability is the average of $\overline{\mathcal{N}}$ over randomly sampled parameters, evaluated on the density matrix at $\boldsymbol{x} = \boldsymbol{0}$.
Note that the mean negativity only captures the average entanglement between single qubits and the rest of the system, such that ansätze with a similar value may still generate structurally different entangled states.
The abbreviations of the ansätze and noise types are explained on the [Setup](setup.md) page.

## Noiseless Circuits
Our Figure 8 in the paper:
![Entanglement](figures/ent_noiseless_light.png#only-light)
![Entanglement](figures/ent_noiseless_dark.png#only-dark)

Entangling capability, measured by the mean negativity $\overline{\mathcal{N}}$ averaged over randomly sampled parameters, for the considered ansätze in a noiseless environment. The bars represent the mean values with error bars from the minimum to maximum highlighted in red across the five seeds.

An increasing qubit count leads to a higher overall value for the entangling capability, while the specific values for the SEA, HEA and RYA are similar.
The CRA, which uses controlled rotations as entangling gates, has a lower entangling capability for more than four qubits.

## Under the Influence of Noise
Our Figure 9 in the paper:
![Entanglement](figures/ent_light.png#only-light)
![Entanglement](figures/ent_dark.png#only-dark)

Entangling capability, measured by the mean negativity $\overline{\mathcal{N}}$ averaged over randomly sampled parameters, under the influence of increasing noise levels. Points represent the mean of five seeds and lines are a linear interpolation to guide the eye. The zero-noise points correspond to the values in Fig. 8. As the relative standard deviation across the five seeds is small (below 1.8%), the mean entangling capability is representative.

The three noise regimes identified for the coefficients are reflected in the entangling capability as well:
Decoherent gate errors (BF, PF and DP) reduce the entangling capability substantially for all ansätze and qubit counts, and the decrease appears to be exponential in the noise level, mirroring the exponential contraction of the Fourier coefficients.
SPAM and damping errors (SP, ME, AD and PD), which act only once per qubit at the boundary of the circuit, lead to a slight decrease of the entangling capability over the tested noise levels.
The sampled mean negativity under coherent gate errors (CGE) remains close to its noiseless value.
