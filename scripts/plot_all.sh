#!/bin/bash

if [ ! "$1" = "only_plot" ]; then
	experiment_id_flag="-eid $(ls -rt mlruns | tail -n 1)"
	## Data export
	cd $GIT_BASE_DIR
	# -coeff:    1D/2D coefficient statistics (coeff_mean/sd/covar, coeff_abs_*, n_freqs);
	#            restricted to the noisy runs of the main study (the noiseless
	#            reference is noise level 0 of these runs), so that the noiseless
	#            runs of the encoding study below are not mixed in
	$GIT_BASE_DIR/.venv/bin/python notebooks/csv_export.py $experiment_id_flag -coeff -nt BitFlip,PhaseFlip,Depolarizing,AmplitudeDamping,PhaseDamping,StatePreparation,Measurement,GateError
	# -enccoeff: full coefficients for the (noiseless) encoding study (coeff_*_encoding)
	# -ent/-expr/-train: entanglement, expressibility and training data
	$GIT_BASE_DIR/.venv/bin/python notebooks/csv_export.py $experiment_id_flag -enccoeff -ent -expr -train
	# -coeffsub: coefficients with selective coherent noise (coeff_mean_subsampling);
	#            only the coherent gate error runs are relevant for this plot
	$GIT_BASE_DIR/.venv/bin/python notebooks/csv_export.py $experiment_id_flag -coeffsub -nt GateError
	cd -
fi

cd $GIT_BASE_DIR/plotting/rplots
if [ ! -d csv_data ]; then
	echo "Could not find csv-data. Please run experiments first, or download the CSV-files from https:/doi.org/10.5281/zenodo.15211318"
	cd -
	exit 1
fi

## Plotting
make

cd -
