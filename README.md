# Out of Tune: Demystifying Noise-Effects on Quantum Fourier Models

This repository contains the source code and additional results for our paper "Out of Tune: Demystifying Noise-Effects on Quantum Fourier Models" submitted at QCE25.

## Results

Looking for supplementary results beyond the scope of the paper? :eyes:
Head over to the [results page](plotting/RESULTS.md).

## Getting Started :rocket:

This repository uses [Kedro](https://kedro.org/). To get started, follow these steps:
1. Clone this repository
2. Run `poetry install` or `pip install -r requirements.txt`
3. Run the experiment: `kedro run`

Experiments are automatically recorded using [MlFlow](https://mlflow.org/). You can view the experiments by
1. Running `poetry run kedro mlflow ui`
2. Navigating to [http://127.0.0.1:5000](http://127.0.0.1:5000)

To visualize the nodes and pipeline
1. Run `poetry run kedro viz`
2. Navigating to [http://127.0.0.1:4141](http://127.0.0.1:4141)

## Tweaking :wrench:

- To specify a pipeline: `kedro run --pipeline NAME`
- Parameters can be adjusted in `conf/base/parameters.yml` or as command line arguments `--params=<key1>=<value1>`

## Reproduction

### Docker

#### Get docker image
Build image:

```docker build -t effect_of_noise_repro .```

#### Create Container

```docker run --name effect_of_noise_repro_cont -it effect_of_noise_repro [<-flags>] [<option>]```

The `<option>` specifies which operations are performed on container start.

Available options are:
* `experiments_paper`\*: performs all experiments shown in the paper
* `plot`: generates the the plots for the paper using R (only available if either the paper experiments are run first, or result data is downloaded from [Zenodo](https://doi.org/10.5281/zenodo.15211318)
* `coefficients`: performs coefficient experiment based on the [configuration](conf/base/parameters.yml)
* `entanglement`: performs entanglement experiment based on the [configuration](conf/base/parameters.yml)
* `expressibility`: performs entanglement experiment based on the [configuration](conf/base/parameters.yml)
* `bash`(default): does not perform any operation, but launches interactive shell, default

Feel free to define additional `<-flags>`, we recommend volumes, e.g.:
Volumes, to keep track of generated files and configuration on the host system:
```
-v $PWD/mlruns:/home/repro/effect-of-noise-in-qfms/mlruns -v $PWD/plotting:/home/repro/effect-of-noise-in-qfms/plotting -v $PWD/conf/base:/home/repro/effect-of-noise-in-qfms/conf/base
```

\*Please note the long runtimes when executing all experiments (hours to days).
For quickly inspecting our reproduction package, we recommend to use the other options.

#### Start a stopped container
Not done yet? You do not have to run a new container for new experiments. Just call:
```
docker start -i effect_of_noise_repro_cont
```
and check out the [scripts](scripts/) folder, or the [instructions](#tweaking) above.
