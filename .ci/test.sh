#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

R CMD build ./r-pkg

echo "--- GET /_cat/aliases"
curl -X GET http://http://127.0.0.1:9200/_cat/aliases

echo "--- running tests"
cd r-pkg/tests/
Rscript testthat.R

export _R_CHECK_CRAN_INCOMING_=false
R CMD check \
    --as-cran \
    ./*.tar.gz
