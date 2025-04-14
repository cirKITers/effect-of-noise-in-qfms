#!/bin/bash

# run experiments with all different circuits
for seed in 1003 1004
do
    echo "Running with seed $seed"
    ./sweep_circuits_seed.sh $seed
done