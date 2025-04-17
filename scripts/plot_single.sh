#!/bin/bash
export GIT_BASE_DIR=$(git rev-parse --show-toplevel)

cd $GIT_BASE_DIR/plotting/rplots

## Data export
cd $GIT_BASE_DIR
python notebooks/csv_export.py -eid $(ls -rt mlruns | tail -n 1) -s
cd -

## Plotting
make single

cd -
