#!/bin/bash

# first argument: seed

# run experiments with all different circuits
for noise in BitFlip PhaseFlip AmplitudeDamping PhaseDamping Depolarizing
do
    echo "Running with noise type $noise"

    ./sweep_qubits_circuits_seed.sh $noise $circuit $1
done