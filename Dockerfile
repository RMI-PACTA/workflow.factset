# using rocker r-vers as a base with R 4.3.1
# https://hub.docker.com/r/rocker/r-ver
# https://rocker-project.org/images/versioned/r-ver.html
#
# sets CRAN repo to use Posit Package Manager to freeze R package versions to
# those available on 2023-10-30
# https://packagemanager.posit.co/client/#/repos/2/overview
# https://packagemanager.posit.co/cran/__linux__/jammy/2023-10-30

# set proper base image
ARG R_VERS="4.3.1"
FROM rocker/r-ver:$R_VERS AS base

# set Docker image labels
LABEL org.opencontainers.image.source=https://github.com/RMI-PACTA/workflow.factset
LABEL org.opencontainers.image.description="Extract FactSet Data for use in PACTA"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title=""
LABEL org.opencontainers.image.revision=""
LABEL org.opencontainers.image.version=""
LABEL org.opencontainers.image.vendor=""
LABEL org.opencontainers.image.base.name=""
LABEL org.opencontainers.image.ref.name=""
LABEL org.opencontainers.image.authors=""

# set apt-get to noninteractive mode
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NOWARNINGS="yes"

RUN groupadd -r runner-workflow-factset \
      && useradd -r -g runner-workflow-factset runner-workflow-factset \
      && mkdir -p /home/runner-workflow-factset \
      && chown -R runner-workflow-factset /home/runner-workflow-factset
WORKDIR /home/runner-workflow-factset

# install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      libicu-dev=70.* \
      libpq-dev=14.* \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# set frozen CRAN repo
ARG CRAN_REPO="https://packagemanager.posit.co/cran/__linux__/jammy/2023-10-30"
RUN echo "options(repos = c(CRAN = '$CRAN_REPO'), pkg.sysreqs = FALSE)" >> "${R_HOME}/etc/Rprofile.site" \
      # install packages for dependency resolution and installation
      && Rscript -e "install.packages(c('pak', 'jsonlite'))"

# copy in everything from this repo
COPY . /workflow.factset

# install R package dependencies
RUN Rscript -e "\
  pak::pkg_install('local::/workflow.factset'); \
  "

USER runner-workflow-factset

# set default run behavior
CMD ["input_dir/default_config.json"]
