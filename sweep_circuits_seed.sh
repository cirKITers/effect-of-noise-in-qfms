#!/bin/bash

# first argument: seed

# run experiments with all different circuits
for circuit in Circuit_1 Circuit_19 Strongly_Entangling Hardware_Efficient
do
    echo "Running with Ansatz $circuit"

    ./sweep_qubits_circuits_seed.sh $circuit $1
done