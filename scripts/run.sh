#!/bin/bash
export GIT_BASE_DIR=$(git rev-parse --show-toplevel)

# in case the script is not started from within the toplevel directory
cd $GIT_BASE_DIR/scripts

if [ "$1" = "experiments_paper" ]; then
	./run_paper_experiments.sh
	./plot_all.sh
elif [ "$1" = "coefficients" ]; then
	./run_coefficient_config.sh
	./plot_single.sh coefficients
elif [ "$1" = "entanglement" ]; then
	./run_entanglement_config.sh
	./plot_single.sh entanglement
elif [ "$1" = "expressibility" ]; then
	./run_expressibility_config.sh
	./plot_single.sh expressibility
elif [ "$1" = "plot_paper_results" ]; then
	./plot_all.sh only_plot
elif [ "$1" = "bash" ]; then
	# launch shell
	cd ..
	/bin/bash
	exit 0
else
    echo "Usage: ./scripts/run.sh [coefficients|expressibility|entanglement|experiments_paper|plot|bash]"
fi

cd -
