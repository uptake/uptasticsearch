#!/bin/bash

# failure is a natural part of life
set -e

if [[ "$TASK" == "rpkg" ]]; then
    R_PACKAGE_DIR=$(pwd)/r-pkg
    Rscript -e "install.packages('lintr')"
    Rscript -e "lintr::lint_package('${R_PACKAGE_DIR}')"
fi

if [[ "$TASK" == "pypkg" ]]; then
    echo "R task only"
fi
