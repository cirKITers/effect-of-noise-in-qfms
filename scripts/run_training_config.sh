#!/bin/bash

# in case the script is not started from within the toplevel directory
cd $GIT_BASE_DIR

echo "Started running training experiment with current configuration in conf/base/parameters.yml"
$GIT_BASE_DIR/.venv/bin/kedro run --pipeline training
sed -i "s/effects_of_noise_in_qfm/training/g" mlruns/$(ls -rt mlruns| tail -n 1)/meta.yaml
echo "Training experiment done"

cd -
