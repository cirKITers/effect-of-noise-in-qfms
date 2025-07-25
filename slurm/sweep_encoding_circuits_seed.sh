#!/bin/bash

# first argument: seed

# run experiments with all different circuits
# Hardware_Efficient Circuit_19 Strongly_Entangling Circuit_15
for encoding in RX RY RZ
do
    echo "Running with Encoding $encoding"

    ~/effect-of-noise-in-qfms/slurm/sweep_qubits_encoding_circuits_seed.sh $encoding $1 $2
    # ~/effect-of-noise-in-qfms/slurm/sweep_qubits_noise_circuits_seed.sh "GateError" $circuit $1
done    