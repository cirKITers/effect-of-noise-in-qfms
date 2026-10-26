#!/bin/bash

# in case the script is not started from within the toplevel directory
if [ ! "${PWD}" = $GIT_BASE_DIR ]; then
    cd $GIT_BASE_DIR
fi

echo "Started running experiments..."
circuits="Hardware_Efficient Strongly_Entangling Circuit_19 Circuit_20"
noise_types="BitFlip PhaseFlip Depolarizing StatePreparation Measurement AmplitudeDamping PhaseDamping GateError"

# Main paper study (1D coefficients, expressibility, entanglement)
for experiment in coefficients entanglement expressibility; do
	echo "Started computing $experiment..."
	for seed in {1000..1004}; do
		for n_qubits in {3..6}; do
			for circuit in $circuits; do
				if [ "$circuit" = "Circuit_20" ]; then
					encoding=RY
				else
					encoding=RX
				fi
				for noise_type in $noise_types; do
					echo "Started experiment $experiment with seed=$seed, n_qubits=$n_qubits, $circuit, encoding=$encoding and noise_type=$noise_type"
						$GIT_BASE_DIR/.venv/bin/kedro run --pipeline $experiment --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.encoding=$encoding,model.circuit_type=$circuit,seed=$seed,model.noise_params.$noise_type=0.03,model.noise_steps=7"
				done
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
					$GIT_BASE_DIR/.venv/bin/kedro run --pipeline coefficients --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.circuit_type=$circuit,seed=$seed,coefficients.scale=False,model.noise_params.$noise_type=0.03,model.noise_steps=7"
			done
		done
	done
done

# Coefficient encoding experiments
echo "Started coefficient encoding experiment"
for seed in {1000..1004}; do
	for n_qubits in {3..6}; do
		for circuit in $circuits; do
			for encoding in RX RY RZ; do
				echo "Started coefficient experiments for encoding with seed=$seed, n_qubits=$n_qubits, $circuit, and encoding=$encoding"
					$GIT_BASE_DIR/.venv/bin/kedro run --pipeline coefficients --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.circuit_type=$circuit,seed=$seed,model.encoding=$encoding,model.noise_steps=7"
			done
		done
	done
done
sed -i "s/effects_of_noise_in_qfm/paper_experiments/g" mlruns/$(ls -rt mlruns| tail -n 1)/meta.yaml

# Run training with all frameworks
echo "Started training experiments..."
for problem_seed in {1000..1009}; do
	for seed in {1000..1009}; do
		for n_qubits in {3..6}; do
			for circuit in $circuits; do
				if [ "$circuit" = "Circuit_20" ]; then
					encoding=RY
				else
					encoding=RX
				fi
				for noise_type in $noise_types; do
					echo "Started experiment training with problem_seed=$problem_seed, seed=$seed, n_qubits=$n_qubits, $circuit, encoding=$encoding and noise_type=$noise_type"
						$GIT_BASE_DIR/.venv/bin/kedro run --pipeline training --params="data.seed=$problem_seed,data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.encoding=$encoding,model.circuit_type=$circuit,seed=$seed,model.noise_params.$noise_type=0.03"
				done
			done
		done
	done
done

echo "all experiments done."

cd -
