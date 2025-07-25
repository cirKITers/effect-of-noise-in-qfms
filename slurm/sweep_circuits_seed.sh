#!/bin/bash

# first argument: seed

# run experiments with all different circuits
# Hardware_Efficient Circuit_19 Strongly_Entangling Circuit_15
for circuit in Hardware_Efficient Circuit_19 Strongly_Entangling Circuit_15
do
    echo "Running with Ansatz $circuit"

    ~/effect-of-noise-in-qfms/slurm/sweep_noise_circuits_seed.sh $circuit $1
    # ~/effect-of-noise-in-qfms/slurm/sweep_encoding_circuits_seed.sh $circuit $1
    # ~/effect-of-noise-in-qfms/slurm/sweep_qubits_noise_circuits_seed.sh "GateError" $circuit $1
done    