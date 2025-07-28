#!/bin/bash

seed=$1

# for n_qubits in {3..5}; do
#     echo "Started running for $n_qubits Qubits and seed $seed."
#     source run_qubit.sh $seed $n_qubits
# done

n_qubits=4
echo "Started running for $n_qubits Qubits and seed $seed."
source run_qubit.sh $seed $n_qubits
