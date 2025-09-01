---
title: Home
---
# Out of Tune: <br> Demystifying Noise-Effects <br> on Quantum Fourier Models

This is website contains supplementary results to our paper ["Out of Tune: Demystifying Noise-Effects on Quantum Fourier Models"](https://arxiv.org/abs/2506.09527) :scroll:.

Checkout the subpages for detailled plots on how noise affects [Coefficients](coefficients.md), [Training](training.md), [Entanglement](entanglement.md) and [Expressibility](expressibility.md) :rocket:.

## Abstract

Variational quantum algorithms have received substantial theoretical and empirical attention.
As the underlying variational quantum circuit (VQC) can be represented by Fourier series that contain an exponentially large spectrum in the number of input features, hope for quantum advantage remains.
Nevertheless, it remains an open problem if and how quantum Fourier models (QFMs) can concretely outperform classical alternatives, as the eventual sources of non-classical computational power (for instance, the role of entanglement) are far from being fully understood. Likewise, hardware noise continues to pose a challenge that will persist also along the path towards fault tolerant quantum computers.

In this work, we study VQCs with Fourier lenses, which provides possibilities to improve their understanding, while also illuminating and quantifying constraints and challenges.
We seek to elucidate critical characteristics of QFMs under the influence of noise.
Specifically, we undertake a systematic investigation into the impact of noise on the Fourier spectrum, expressibility, and entangling capability of QFMs through extensive numerical simulations and link these properties to training performance. The insights may inform more efficient utilisation of quantum hardware and support the design of tailored error mitigation and correction strategies.

Decoherence imparts an expected and broad detrimental influence across all Ansätze.
Nonetheless, we observe that the severity of these deleterious effects varies among different model architectures, suggesting that certain configurations may exhibit enhanced robustness to noise and show computational utility.

