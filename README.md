# Disentangling Entanglement


## Getting Started :rocket:

This repository uses [Kedro](https://kedro.org/). To get started, follow these steps:
1. Clone this repository
2. Run `poetry install` or `pip install -r requirements.in`
3. Run the experiment: `kedro run`
   - To specify a pipeline: `kedro run --pipeline NAME`
   - Parameters can be adjusted in `conf\base\parameters.yml`

Experiments are automatically recorded using [MlFlow](https://mlflow.org/). You can view the experiments by
1. Running `poetry run kedru mlflow ui`
2. Navigating to [http://127.0.0.1:5000](http://127.0.0.1:5000)