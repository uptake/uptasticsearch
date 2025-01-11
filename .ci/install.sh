#!/bin/bash

# failure is a natural part of life
set -e

if [[ "$TASK" == "rpkg" ]]; then
  R CMD INSTALL \
    --clean \
    $(pwd)/r-pkg
fi
