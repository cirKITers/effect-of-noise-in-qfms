#!/bin/bash

export GIT_BASE_DIR=$(git rev-parse --show-toplevel)
if [ $1 = "only_plot" ]; then
	experiment_id_flag = ""
else
	experiment_id_flag = "-eid $(ls -rt mlruns | tail -n 1)"
fi

## Data export
cd $GIT_BASE_DIR
python notebooks/csv_export.py $experiment_id_flag
cd -

cd $GIT_BASE_DIR/plotting/rplots
if [ ! csv_data ]; then
	echo "Could not find csv-data. Please run experiments first, or download the CSV-files from https:/doi.org/10.5281/zenodo.15211318"
	cd -
	exit 1
fi

## Plotting
make

cd -
