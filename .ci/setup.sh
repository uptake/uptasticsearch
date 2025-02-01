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
    devscripts \
    texinfo \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    tidy \
    qpdf

Rscript -e "install.packages(c('covr', 'data.table', 'futile.logger', 'httr', 'jsonlite', 'knitr', 'lintr', 'markdown', 'purrr', 'stringr', 'testthat'), repos = 'https://cran.r-project.org', Ncpus = parallel::detectCores())"
cp test-data/* r-pkg/inst/testdata/
