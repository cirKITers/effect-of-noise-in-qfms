#!/bin/bash
export GIT_BASE_DIR=$(git rev-parse --show-toplevel)

if [ $1 = "coefficients" ]; then
	experiment_id_flag="-coeff"
	make_target=single_coeff
elif [ $1 = "expressibility" ]; then
	experiment_id_flag="-expr"
	make_target=single_expr
elif [ $1 = "entanglement" ]; then
	experiment_id_flag="-ent"
	make_target=single_ent
else
	echo "Unknown experiment type: $1"
fi

cd $GIT_BASE_DIR/plotting/rplots

## Data export
cd $GIT_BASE_DIR
$GIT_BASE_DIR/.venv/bin/python notebooks/csv_export.py -eid $(ls -rt mlruns | tail -n 1) -s -coeff -ent -expr
cd -

## Plotting
make $make_target

cd -
