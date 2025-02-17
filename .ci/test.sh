#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

R CMD build ./r-pkg

echo "--- trying GET /_cat/indices ---"
curl \
    -i \
    -X GET \
    -H 'Accept: application/json' \
    '127.0.0.1:9200/_cat/indices?format=json'

echo "--- checking that the container is still up ---"
docker ps

# TODO(jameslamb): remove this before merging
R CMD INSTALL ./*.tar.gz
pushd ./r-pkg/tests
Rscript testthat.R

exit 123

export _R_CHECK_CRAN_INCOMING_=false
R CMD check \
    --as-cran \
    ./*.tar.gz
