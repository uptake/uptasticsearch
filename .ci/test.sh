#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

R CMD build ./r-pkg

# echo "--- POST /_aliases"
# curl \
#     -i \
#     -X POST \
#     -H 'Content-Type: application/json' \
#     -d '{"actions": [{"add": {"index": "shakespeare", "alias": "the_test_alias"}}]}' \
#     http://127.0.0.1:9200/_aliases

# echo ""
# echo "--- GET /_cat/aliases"
# curl -i -X GET http://127.0.0.1:9200/_cat/aliases

echo ""
echo "--- running tests"
cd r-pkg/tests/
Rscript testthat.R

export _R_CHECK_CRAN_INCOMING_=false
R CMD check \
    --as-cran \
    ./*.tar.gz
