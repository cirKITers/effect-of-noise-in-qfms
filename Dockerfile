FROM ubuntu:24.04

LABEL author="Maja Franz <maja.franz@othr.de>, Melvin Strobl <melvin.strobl@kit.edu>"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

# Install required packages
RUN apt-get update -y
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa # For Python 3.12
RUN apt-get install -y \
    python3.12 \
    python3-pip \
    python3-venv \
    python3.12-dev \
    git \
    r-base \
    texlive-latex-base \
    sudo

# Install R packages for plotting
RUN R -e "install.packages('tidyverse',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggh4x',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggrastr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('tikzDevice',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('scales',dependencies=TRUE, repos='http://cran.rstudio.com/')"

# Let Python 3.12 be global python version
RUN ln -s /usr/bin/python3.12 /usr/bin/python

# Add user
RUN useradd -m -G sudo -s /bin/bash repro && echo "repro:repro" | chpasswd
RUN usermod -a -G ubuntu repro
USER repro

# Clone Repo
WORKDIR /home/repro
RUN git clone https://github.com/cirKITers/effect-of-noise-in-qfms
WORKDIR /home/repro/effect-of-noise-in-qfms

# install python packages
ENV PATH=$PATH:/home/repro/.local/bin
# set default python version to 3.12
RUN echo 'alias python="python3.12"' >> /home/repro/.bashrc

RUN /usr/bin/python3.12 -m venv .venv
RUN .venv/bin/python -m pip install -r requirements.txt

# Experiments can be run and plots can be generated when container is started,
# see options in README or run script
# ENTRYPOINT ["./scripts/run.sh"]
CMD ["bash"]
