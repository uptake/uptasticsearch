#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

R CMD INSTALL \
    --clean \
    ./r-pkg
