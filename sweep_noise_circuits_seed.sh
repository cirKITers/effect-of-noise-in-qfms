#!/bin/bash

# first argument: seed

# run experiments with all different circuits
for noise in BitFlip PhaseFlip AmplitudeDamping PhaseDamping Depolarizing StatePreparation GateError Measurement
do
    echo "Running with noise type $noise"

    ./sweep_qubits_noise_circuits_seed.sh $noise $1 $2
done