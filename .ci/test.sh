#!/bin/bash

# failure is a natural part of life
set -e

if [[ "$TASK" == "rpkg" ]]; then
  Rscript .ci/lint_r_code.R $(pwd)
  R CMD build $(pwd)/r-pkg
  export _R_CHECK_CRAN_INCOMING_=false
  R CMD check \
    --as-cran \
    *.tar.gz
fi

if [[ "$TASK" == "pypkg" ]]; then
  pip install wheel
  pytest \
    --verbose \
    $(pwd)/py-pkg
fi
