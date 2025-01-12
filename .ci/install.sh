#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

if [[ "$TASK" == "rpkg" ]]; then
    R CMD INSTALL \
        --clean \
        ./r-pkg
fi
