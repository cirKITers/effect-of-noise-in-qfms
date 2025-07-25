#!/bin/bash
# 
# name of the job for better recognizing it in the queue overview
#SBATCH --job-name=effects-of-noise
# 
# define how many nodes we need
#SBATCH --nodes=1
#
# we only need on 1 cpu at a time
#SBATCH --ntasks=6
#
# expected duration of the job
#              hh:mm:ss
#SBATCH --time=15:00:00
# 
# partition the job will run on
#SBATCH --partition cpu
# 
# expected memory requirements
#SBATCH --mem=32000MB
#
# infos
#
# output path
#SBATCH --output="~/effect-of-noise-in-qfms/logs/slurm/slurm-%j-%x.out"

module load devel/python/3.11.7
# ~/effect-of-noise-in-qfms/.venv/bin/python -m kedro run --pipeline coefficients --params=$1
# ~/effect-of-noise-in-qfms/.venv/bin/python -m kedro run --pipeline entanglement --params=$1
~/effect-of-noise-in-qfms/.venv/bin/python -m kedro run --pipeline training --params=$1
# ~/effect-of-noise-in-qfms/.venv/bin/python -m kedro run --pipeline expressibility --params=$1

# Done
exit 0


