module load devel/python/3.11.7
source ~/effect-of-noise-in-qfms/.venv/bin/activate

mlflow experiments create -n $1
