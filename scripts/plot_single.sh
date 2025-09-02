#!/bin/bash
which Rscript

if [ "$1" = "coefficients" ]; then
	experiment_id_flag="-coeff"
	make_target=single_coeff
elif [ "$1" = "expressibility" ]; then
	experiment_id_flag="-expr"
	make_target=single_expr
elif [ "$1" = "entanglement" ]; then
	experiment_id_flag="-ent"
	make_target=single_ent
elif [ "$1" = "training" ]; then
	experiment_id_flag="-train"
	make_target=single_train
else
	echo "Unknown experiment type: $1"
fi

cd $GIT_BASE_DIR/plotting/rplots

## Data export
cd $GIT_BASE_DIR
$GIT_BASE_DIR/.venv/bin/python notebooks/csv_export.py -eid $(ls -rt mlruns | tail -n 1) -s $experiment_id_flag
cd -

## Plotting
make $make_target

cd -
