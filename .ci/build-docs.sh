#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

# `devscripts` is required for 'checkbashisms' (https://github.com/r-lib/actions/issues/111)
sudo apt-get update
sudo apt-get install \
    --no-install-recommends \
    -y \
    --allow-downgrades \
    libcurl4-openssl-dev \
    curl \
    texinfo \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    tidy

Rscript -e "install.packages(c('assertthat', 'data.table', 'futile.logger', 'httr', 'jsonlite', 'knitr', 'markdown', 'purrr', 'stringr', 'uuid'), repos = 'https://cran.r-project.org', Ncpus = parallel::detectCores())"

pushd ./r-pkg
R CMD INSTALL --with-keep.source .
Rscript -e "roxygen2::roxygenize()"
Rscript -e "pkgdown::build_site()"
popd
