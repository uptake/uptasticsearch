
set -e

WDIR=$(pwd)
TESTDIR=${WDIR}/sandbox
ES_HOST="127.0.0.1:9200"

# Move to temp directory
mkdir -p ${TESTDIR}

# Get data
cp inst/testdata/shakespeare_mapping.json ${TESTDIR}/shakespeare_mapping.json
cd ${TESTDIR}

# Create shakespeare index and shakespeare mapping
curl --silent \
     -X PUT "http://${ES_HOST}/shakespeare" \
     -H 'Content-Type: application/json' \
     -d @shakespeare_mapping.json

# Upload data
curl --silent \
     -X POST "http://${ES_HOST}/shakespeare/_bulk" \
     -H 'Content-Type: application/json' \
     --data-binary "sample.json";

# Add an intentionally empty index
curl --silent \
     -X PUT "http://${ES_HOST}/empty_index" \
     -H 'Content-Type: application/json' \
     -d @shakespeare_mapping.json

# Check that we got something
curl -X GET "http://${ES_HOST}/shakespeare/_search?size=1"
