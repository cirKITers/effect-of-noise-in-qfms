#!/bin/bash

# in case the script is not started from within the experiment directory
if [ ! "${PWD}" = "/home/repro/effect-of-noise-in-qfms" ]; then
    cd /home/repro/effect-of-noise-in-qfms
fi

echo "started running experiments..."

# Main paper study
for seed in {1000..1004}; do
	for n_qubits in {3..6}; do
		for circuit in Hardware_Efficient Strongly_Entangling Circuit_19 Circuit_15; do
			if [ $circuit -eq Circuit_15 ]; then
				encoding=RY
			else
				encoding=RX
			fi
			for noise_type in BitFlip PhaseFlip Depolarizing StatePreparation Measurement AmplitudeDamping PhaseDamping GateError; do
				for experiment in coefficients entanglement expressibility; do
					echo "Started experiment $experiment with seed=$seed, n_qubits=$n_qubits, $circuit, $encoding=encoding and noise_type=$noise_type"
					~/effect-of-noise-in-qfms/.venv/bin/kedro run --pipeline $experiment --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.encoding=$encoding,model.circuit_type=$circuit,seed=$seed"
				done
			done
		done
	done
done

# Run training with all frameworks
echo "all experiments done."

cd ..
