#!/bin/bash
export GIT_BASE_DIR=$(git rev-parse --show-toplevel)

# in case the script is not started from within the toplevel directory
if [ ! "${PWD}" = $GIT_BASE_DIR ]; then
    cd $GIT_BASE_DIR
fi

echo "Started running entanglement experiment with current configuration in conf/base/parameters.yml"
$GIT_BASE_DIR/.venv/bin/kedro run --pipeline entanglement --params="model.encoding=RX"
sed -i "s/effects_of_noise_in_qfm/entanglement/g" mlruns/$(ls -rt mlruns| tail -n 1)/meta.yaml
echo "Entanglement experiment done"

cd -
