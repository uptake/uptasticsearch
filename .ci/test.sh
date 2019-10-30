#!/bin/bash

# failure is a natural part of life
set -e

if [[ "$TASK" == "rpkg" ]]; then
  R_PACKAGE_DIR=$(pwd)/r-pkg
  Rscript .ci/lint.R ${R_PACKAGE_DIR}

  R CMD build ${R_PACKAGE_DIR}
  R CMD check \
    --as-cran \
    *.tar.gz
fi

if [[ "$TASK" == "pypkg" ]]; then
  PY_PACKAGE_DIR=$(pwd)/py-pkg
  pytest \
    --verbose \
    ${PY_PACKAGE_DI}
fi
