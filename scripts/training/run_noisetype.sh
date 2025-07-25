#/bin/bash

seed=$1
n_qubits=$2
circuit=$3
encoding=$4
noise_type=$5

for problem_seed in {2000..2008}; do
    echo "Started training with seed=$seed, n_qubits=$n_qubits, $circuit, $encoding encoding, noise_type=$noise_type and problem_seed=$problem_seed"
    kedro run --pipeline training --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.circuit_type=$circuit,model.encoding=$encoding,seed=$seed,model.noise_params.$noise_type=0.03,data.seed=$problem_seed" > "logs/s$seed,q$n_qubits,$circuit,$noise_type,ps$problem_seed" 2>&1 &
    sleep 1
done

problem_seed=2009
echo "Started training with seed=$seed, n_qubits=$n_qubits, $circuit, $encoding encoding, noise_type=$noise_type and problem_seed=$problem_seed"
kedro run --pipeline training --params="data.omegas=$n_qubits,model.n_qubits=$n_qubits,model.circuit_type=$circuit,model.encoding=$encoding,seed=$seed,model.noise_params.$noise_type=0.03,data.seed=$problem_seed" > "logs/s$seed,q$n_qubits,$circuit,$noise_type,ps$problem_seed" 2>&1
sleep 1
