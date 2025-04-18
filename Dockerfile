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
    build-essential \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libtiff-dev \
    libudunits2-dev \
    libcairo2-dev \
    sudo

# Let Python 3.12 be global python version
RUN ln -s /usr/bin/python3.12 /usr/bin/python

# Add user
RUN userdel -r ubuntu
RUN useradd -m -u 1000 -G sudo -o -s /bin/bash repro && echo "repro:repro" | chpasswd
USER repro

# Install R packages for plotting
RUN mkdir /home/repro/R
ENV R_LIBS_USER="/home/repro/R"
RUN R -e "install.packages('tidyverse',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggh4x',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggrastr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('tikzDevice',dependencies=TRUE, repos='http://cran.rstudio.com/')"

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

ENV GIT_DISCOVERY_ACROSS_FILESSYSTEM=1

# Experiments can be run and plots can be generated when container is started,
# see options in README or run script
ENTRYPOINT ["./scripts/run.sh"]
CMD ["bash"]
