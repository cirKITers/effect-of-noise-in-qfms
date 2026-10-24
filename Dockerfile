FROM ubuntu:24.04

LABEL author="Maja Franz <maja.franz@othr.de>, Melvin Strobl <melvin.strobl@kit.edu>"

# uv manages the python environment
COPY --from=ghcr.io/astral-sh/uv:0.13.4 /uv /uvx /bin/

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

# Install required packages
RUN apt-get update -y
RUN apt-get install -y \
    python3.12 \
    python3.12-dev \
    git \
    r-base \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-luatex \
    texlive-publishers \
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

# Add user. Use the same UID/GID as the host user to make the mounted volumes
# writable, e.g. docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) ...
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu
RUN groupadd -g "$GID" -o repro \
    && useradd -m -u "$UID" -g "$GID" -G sudo -o -s /bin/bash repro \
    && echo "repro:repro" | chpasswd
USER repro

# Install R packages for plotting
RUN mkdir /home/repro/R
ENV R_LIBS_USER="/home/repro/R"
RUN R -e "install.packages('tidyverse',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggh4x',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggrastr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('tikzDevice',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggnewscale',dependencies=TRUE, repos='http://cran.rstudio.com/')"

# Copy the local checkout (result directories are excluded via .dockerignore)
WORKDIR /home/repro/effect-of-noise-in-qfms
COPY --chown=repro:repro . .

# install python packages
ENV PATH=$PATH:/home/repro/.local/bin
# set default python version to 3.12
RUN echo 'alias python="python3.12"' >> /home/repro/.bashrc

# install the locked dependencies into .venv using the system python 3.12
# (the scripts in scripts/ rely on .venv/bin/kedro and .venv/bin/python)
ENV UV_PYTHON_DOWNLOADS=never
ENV UV_LINK_MODE=copy
RUN uv sync --frozen --no-dev

ENV GIT_DISCOVERY_ACROSS_FILESSYSTEM=1

# Experiments can be run and plots can be generated when container is started,
# see options in README or run script
ENTRYPOINT ["./scripts/run.sh"]
CMD ["bash"]
