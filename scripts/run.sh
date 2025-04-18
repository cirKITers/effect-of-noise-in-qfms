#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: ./scripts/run.sh [all|experiments|plot|bash]"
	exit 1
fi

# in case the script is not started from within the experiment directory
if [ ! "${PWD}" = "/home/repro/effect-of-noise-in-qfms" ]; then
    cd /home/repro/effect-of-noise-in-qfms
fi

export PYTHONPATH=/home/repro/effect-of-noise-in-qfms:$PYTHONPATH

cd scripts/

if [ "$1" = "all" ]; then
	./run_experiments.sh
#	./generate_plots.sh
elif [ "$1" = "experiments" ]; then
	./run_experiments.sh
# elif [ "$1" = "plot" ]; then
# 	./generate_plots.sh
elif [ "$1" = "bash" ]; then
	# launch shell
	cd ..
	/bin/bash
	exit 0
else
    echo "Usage: ./scripts/run.sh [all|experiments|plot|bash]"
fi

cd ..

# launch shell
/bin/bash
