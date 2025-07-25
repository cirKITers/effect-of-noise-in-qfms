#!/bin/bash

# first argument: number of qubits
# second argument: seed

# run experiments with all different qubits
for n_qubits in 3 4 5 6
do
    echo "Running with $n_qubits qubits"
        # kedro run --pipeline training --params=omegas=$n_qubits,n_qubits=$n_qubits,circuit_type=$1,seed=$2 &
    sbatch --job-name "q$n_qubits-n$1-c$2-s$3" ~/effect-of-noise-in-qfms/slurm/slurm_job.sh "data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.noise_params.$1=0.03,model.circuit_type=$2,seed=$3" &

    sleep 1
done