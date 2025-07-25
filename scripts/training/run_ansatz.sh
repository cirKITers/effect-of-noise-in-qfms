#/bin/bash

seed=$1
n_qubits=$2
circuit=$3
encoding=$4

for noise_type in BitFlip PhaseFlip Depolarizing StatePreparation Measurement AmplitudeDamping PhaseDamping; do
    echo "Started training with seed=$seed, n_qubits=$n_qubits, $circuit, $encoding encoding and noise_type=$noise_type"
    source run_noisetype.sh $seed $n_qubits $circuit $encoding $noise_type &
    sleep 1
done

noise_type=GateError
echo "Started training with seed=$seed, n_qubits=$n_qubits, $circuit, $encoding encoding and noise_type=$noise_type"
source run_noisetype.sh $seed $n_qubits $circuit $encoding $noise_type
sleep 1
