#!/bin/bash

# failure is a natural part of life
set -e

if [[ "$TASK" == "rpkg" ]]; then
  Rscript -e " \
    Sys.setenv(NOT_CRAN = 'true'); \
    covr::codecov('r-pkg/') \
    "
fi
