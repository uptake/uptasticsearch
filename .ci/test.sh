#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

R CMD build ./r-pkg

# TODO(jameslamb): remove this before merging
R CMD INSTALL ./*.tar.gz
pushd ./r-pkg/tests
Rscript testthat.R

exit 1

export _R_CHECK_CRAN_INCOMING_=false
R CMD check \
    --as-cran \
    ./*.tar.gz
