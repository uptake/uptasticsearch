#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

# setup LaTeX stuff
brew install basictex
export PATH="/Library/TeX/texbin:$PATH"
sudo tlmgr --verify-repo=none update --self
sudo tlmgr --verify-repo=none install inconsolata helvetic rsfs

# install dependencies
Rscript -e "install.packages(c('assertthat', 'data.table', 'futile.logger', 'httr', 'jsonlite', 'knitr', 'markdown', 'pkgdown', 'purrr', 'roxygen2', 'stringr', 'uuid'), repos = 'https://cran.r-project.org', Ncpus = parallel::detectCores())"

# build the docs
pushd ./r-pkg
R CMD INSTALL --with-keep.source .
Rscript -e "roxygen2::roxygenize()"
Rscript -e "pkgdown::build_site()"
popd
