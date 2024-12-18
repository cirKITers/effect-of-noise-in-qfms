#!/bin/bash

# first argument: seed

# run experiments with all different circuits
for circuit in Hardware_Efficient
do
    echo "Running with Ansatz $circuit"

    ./sweep_noise_circuits_seed.sh $circuit $1
done