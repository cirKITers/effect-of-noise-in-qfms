#!/bin/bash

seed=$1
n_qubits=$2
encoding=RX

for circuit in Hardware_Efficient Strongly_Entangling Circuit_19; do
    echo "Started running for $circuit Ansatz, $n_qubits Qubits, seed $seed, encoding $encoding"
    source run_ansatz.sh $seed $n_qubits $circuit $encoding
done

circuit=Circuit_15
encoding=RY
echo "Started running for $circuit Ansatz, $n_qubits Qubits, seed $seed, encoding $encoding"
source run_ansatz.sh $seed $n_qubits $circuit $encoding
