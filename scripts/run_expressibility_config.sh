#!/bin/bash

# in case the script is not started from within the toplevel directory
if [ ! "${PWD}" = $GIT_BASE_DIR ]; then
    cd $GIT_BASE_DIR
fi

echo "Started running expressibility experiment with current configuration in conf/base/parameters.yml"
$GIT_BASE_DIR/.venv/bin/kedro run --pipeline expressibility --params="model.encoding=RX"
sed -i "s/effects_of_noise_in_qfm/expressibility/g" mlruns/$(ls -rt mlruns| tail -n 1)/meta.yaml
echo "Expressibility experiment done"

cd -
