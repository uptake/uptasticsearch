#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

R CMD build ./r-pkg
export _R_CHECK_CRAN_INCOMING_=false
R CMD check \
    --as-cran \
    ./*.tar.gz
