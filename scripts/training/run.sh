#!/bin/bash

echo "Started running experiments..."

for seed in {1000..1009}; do
    source run_seed.sh $seed
done

# sed -i "s/effects_of_noise_in_qfm/training/g" mlruns/$(ls -rt mlruns| tail -n 1)/meta.yaml

echo "all experiments done."
