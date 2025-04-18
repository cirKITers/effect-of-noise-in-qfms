#!/bin/bash

if [ ! "$1" = "only_plot" ]; then
	experiment_id_flag="-eid $(ls -rt mlruns | tail -n 1)"
	## Data export
	cd $GIT_BASE_DIR
	$GIT_BASE_DIR/.venv/bin/python notebooks/csv_export.py $experiment_id_flag -coeff -ent -expr
	cd -
fi

cd $GIT_BASE_DIR/plotting/rplots
if [ ! csv_data ]; then
	echo "Could not find csv-data. Please run experiments first, or download the CSV-files from https:/doi.org/10.5281/zenodo.15211318"
	cd -
	exit 1
fi

## Plotting
make

cd -
