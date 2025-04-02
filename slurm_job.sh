#!/bin/bash
# 
# name of the job for better recognizing it in the queue overview
#SBATCH --job-name=dis-ent
# 
# define how many nodes we need
#SBATCH --nodes=1
#
# we only need on 1 cpu at a time
#SBATCH --ntasks=6
#
# expected duration of the job
#              hh:mm:ss
#SBATCH --time=5:00:00
# 
# partition the job will run on
#SBATCH --partition single
# 
# expected memory requirements
#SBATCH --mem=12000MB
#
# infos
#
# output path
#SBATCH --output="logs/slurm/slurm-%j-%x.out"

module load devel/python/3.11.7
~/effects_of_noise_in_qfm/.venv/bin/python -m kedro run --pipeline coefficients --params=$1
# ~/effects_of_noise_in_qfm/.venv/bin/python -m kedro run --pipeline entanglement --params=$1
# ~/effects_of_noise_in_qfm/.venv/bin/python -m kedro run --pipeline expressibility --params=$1

# Done
exit 0


