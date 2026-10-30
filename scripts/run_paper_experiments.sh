#!/bin/bash

# in case the script is not started from within the toplevel directory
if [ ! "${PWD}" = $GIT_BASE_DIR ]; then
    cd $GIT_BASE_DIR
fi

echo "Started running experiments..."
circuits="Hardware_Efficient Strongly_Entangling Circuit_19 Circuit_20"
noise_types="BitFlip PhaseFlip Depolarizing StatePreparation Measurement AmplitudeDamping PhaseDamping GateError"

# All runs below are recorded in the same MLflow experiment (the default one
# named after the package). It is renamed to "paper_experiments" at the very
# end, because renaming it in between would make kedro-mlflow create a new
# experiment for the remaining runs and the data export in plot_all.sh only
# reads the most recent experiment.

# Main paper study (expressibility, entanglement)
for experiment in entanglement expressibility; do
	echo "Started computing $experiment..."
	for seed in {1000..1004}; do
		for n_qubits in {3..6}; do
			for circuit in $circuits; do
				for noise_type in $noise_types; do
					echo "Started experiment $experiment with seed=$seed, n_qubits=$n_qubits, $circuit and noise_type=$noise_type"
						$GIT_BASE_DIR/.venv/bin/kedro run --pipeline $experiment --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.encoding=RY,model.circuit_type=$circuit,seed=$seed,model.noise_params.$noise_type=0.03,model.noise_steps=6"
				done
			done
		done
	done
done

# Main paper study (1D coefficients)
echo "Started computing coefficients..."
for seed in {1000..1004}; do
	for n_qubits in {3..6}; do
		for circuit in $circuits; do
			for encoding in RX RY; do
				for noise_type in $noise_types; do
					echo "Started experiment coefficients with seed=$seed, n_qubits=$n_qubits, $circuit, encoding=$encoding and noise_type=$noise_type"
						$GIT_BASE_DIR/.venv/bin/kedro run --pipeline coefficients --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.encoding=$encoding,model.circuit_type=$circuit,seed=$seed,model.noise_params.$noise_type=0.03,model.noise_steps=6"
				done
			done
		done
	done
done

# Entanglement Noiseless study (Meyer-Wallach)
echo "Started computing Meyer-Wallach Entanglement (noiseless) ..."
for seed in {1000..1004}; do
	for n_qubits in {3..6}; do
		for circuit in $circuits; do
			echo "Started experiment of noiseless entanglement with seed=$seed, n_qubits=$n_qubits and $circuit"
					$GIT_BASE_DIR/.venv/bin/kedro run --pipeline entanglement --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.encoding=RY,model.circuit_type=$circuit,seed=$seed,entanglement.measure=MW"
		done
	done
done

# Entanglement Noisy study (Mean Negativity)
echo "Started computing Mean Negativity Entanglement ..."
for seed in {1000..1004}; do
	for n_qubits in {3..6}; do
		for circuit in $circuits; do
			for noise_type in $noise_types; do
				echo "Started experiment of mean negativity entanglement with seed=$seed, n_qubits=$n_qubits, $circuit and noise_type=$noise_type"
					$GIT_BASE_DIR/.venv/bin/kedro run --pipeline entanglement --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.encoding=RY,model.circuit_type=$circuit,seed=$seed,model.noise_params.$noise_type=0.03,model.noise_steps=6,entanglement.measure=MN"
			done
		done
	done
done

# 2D coefficients
# Explicitly set the encoding in the parameters (Kedro not supporting python lists in CLI)
sed -i "s/encoding: .*$/encoding: [\"RX\", \"RY\"]/" conf/base/parameters.yml
echo "Started 2D coefficient experiments"
for seed in {1000..1004}; do
	for n_qubits in {3..6}; do
		for circuit in $circuits; do
			for noise_type in $noise_types; do
				echo "Started 2D coefficients with seed=$seed, n_qubits=$n_qubits, $circuit, and noise_type=$noise_type"
					$GIT_BASE_DIR/.venv/bin/kedro run --pipeline coefficients --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.circuit_type=$circuit,seed=$seed,coefficients.scale=False,model.noise_params.$noise_type=0.03,model.noise_steps=6"
			done
		done
	done
done

# Restore the default (1D) encoding in the parameters
sed -i "s/encoding: .*$/encoding: [\"RY\"]/" conf/base/parameters.yml

# Coefficient encoding experiments (noiseless only). These are the only
# noiseless coefficient runs, which is how the data export tells them apart
# from the main coefficient study.
echo "Started coefficient encoding experiment"
for seed in {1000..1004}; do
	for n_qubits in {3..6}; do
		for circuit in $circuits; do
			for encoding in RX RY RZ; do
				echo "Started coefficient experiments for encoding with seed=$seed, n_qubits=$n_qubits, $circuit, and encoding=$encoding"
					$GIT_BASE_DIR/.venv/bin/kedro run --pipeline coefficients --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.circuit_type=$circuit,seed=$seed,model.encoding=$encoding"
			done
		done
	done
done

# Selective coherent noise study (coefficient mean over frequencies when the
# coherent gate error acts only on the encoding gates (iec), only on the
# variational gates (pqc) or on the full circuit (both)). These runs use an
# oversampling of 20 for the coefficient spectrum, which is also what
# distinguishes them from the main coefficient study in the data export.
echo "Started selective coherent noise coefficient experiments"
for seed in {1000..1004}; do
	for circuit in $circuits; do
		for selective_noise in iec pqc both; do
			echo "Started selective noise coefficients with seed=$seed, n_qubits=6, $circuit and selective_noise=$selective_noise"
				$GIT_BASE_DIR/.venv/bin/kedro run --pipeline coefficients --params="data.omegas=6,model.n_qubits=6,model.encoding=RY,model.circuit_type=$circuit,seed=$seed,model.noise_params.GateError=0.03,model.noise_steps=6,coefficients.selective_noise=$selective_noise,coefficients.oversampling=20"
		done
	done
done

# Run training with all frameworks
echo "Started training experiments..."
for problem_seed in {1000..1009}; do
	for seed in {1000..1009}; do
		for circuit in $circuits; do
			for noise_type in $noise_types; do
				echo "Started experiment training with problem_seed=$problem_seed, seed=$seed, n_qubits=6, $circuit and noise_type=$noise_type"
					$GIT_BASE_DIR/.venv/bin/kedro run --pipeline training --params="data.seed=$problem_seed,data.omegas=6,model.n_qubits=6,model.encoding=RY,model.circuit_type=$circuit,seed=$seed,model.noise_params.$noise_type=0.03,training.measure=MN"
			done
		done
	done
done

sed -i "s/effects_of_noise_in_qfm/paper_experiments/g" mlruns/$(ls -rt mlruns| tail -n 1)/meta.yaml

echo "all experiments done."

cd -
