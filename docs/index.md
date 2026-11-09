---
title: Home
---
# Out of Tune: <br> Demystifying Noise-Effects <br> on Quantum Fourier Models

This is website contains supplementary results to our paper "Out of Tune: Demystifying Noise-Effects on Quantum Fourier Models" available on [ArXiv](https://arxiv.org/abs/2506.09527) :scroll:.

Checkout the subpages for detailled plots on how noise affects [Coefficients](coefficients.md), [Training](training.md), [Entanglement](entanglement.md) and [Expressibility](expressibility.md) :rocket:.
The [Setup](setup.md) page summarises the noise models, ansätze and experimental protocol that all results share.
In addition to our [Github repository](https://github.com/cirkiters/effect-of-noise-in-qfms), we provide a reproduction package on [Zenodo](https://doi.org/10.5281/zenodo.16963959).

## Abstract

Variational quantum algorithms have received substantial theoretical and empirical attention.
As the underlying variational quantum circuits (VQCs) can be represented by Fourier series whose spectra grow exponentially with the number of input features, hope for quantum advantage remains.
Nevertheless, whether and how quantum Fourier models (QFMs) can outperform classical alternatives remains an open question, as the sources of non-classical computational power (for instance, the role of entanglement) are not yet fully understood.
Likewise, hardware noise continues to pose a challenge along the path towards fault-tolerant quantum computers.

In this work, we study VQCs through Fourier analysis to better understand their properties and quantify their constraints.
We seek to elucidate critical characteristics of QFMs under the influence of noise.
Specifically, we undertake a systematic investigation into the impact of noise on the Fourier spectrum, expressibility, and entangling capability of QFMs through extensive numerical simulations and link these properties to training performance.
The insights may inform more efficient utilisation of quantum hardware and support the design of tailored error mitigation and correction strategies.

Even without noise, frequency availability does not guarantee a match to the target coefficients within the optimisation budget.
Under the tested conditions, decoherent gate errors applied throughout the circuit contract coefficient magnitudes and degrade fitting, while boundary noise and fixed additive coherent errors have smaller effects.
Sampled expressibility and entangling capability do not consistently rank fitting performance, while frequency-resolved coefficient errors identify the remaining mismatch with the target.
