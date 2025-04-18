#!/bin/bash
export GIT_BASE_DIR=$(git rev-parse --show-toplevel)

# in case the script is not started from within the toplevel directory
cd $GIT_BASE_DIR

echo "Started running coefficient experiment with current configuration in conf/base/parameters.yml"
$GIT_BASE_DIR/.venv/bin/kedro run --pipeline coefficients
sed -i "s/effects_of_noise_in_qfm/coefficients/g" mlruns/$(ls -rt mlruns| tail -n 1)/meta.yaml
echo "Coefficient experiment done"

cd -
