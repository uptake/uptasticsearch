#!/bin/bash

# failure is a natural part of life
set -e

if [[ "$TASK" == "rpkg" ]]; then
  R_PACKAGE_DIR=$(pwd)/r-pkg
  R CMD INSTALL \
    --clean \
    ${R_PACKAGE_DIR}
  cd $(pwd)/r-pkg/tests
  Rscript testthat.R
  exit 10
fi

if [[ "$TASK" == "pypkg" ]]; then
  PY_PACKAGE_DIR=$(pwd)/py-pkg
  pip install ${PY_PACKAGE_DIR}
fi
