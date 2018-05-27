
set -e

WDIR=$(pwd)
TESTDIR=${WDIR}/sandbox
MAPPING_FILE=inst/testdata/es6_shakespeare_mapping.json
SAMPLE_DATA_FILE=inst/testdata/sample.json
ES_HOST="127.0.0.1:9200"

# Move to temp directory
mkdir -p ${TESTDIR}

# Get data
cp ${MAPPING_FILE} ${TESTDIR}/shakespeare_mapping.json
cp ${SAMPLE_DATA_FILE} ${TESTDIR}/sample.json
cd ${TESTDIR}

# Create shakespeare index and shakespeare mapping
curl --silent \
     -X PUT "http://${ES_HOST}/shakespeare" \
     -H 'Content-Type: application/json' \
     -d @shakespeare_mapping.json

# Upload data
curl --silent \
     -X POST "http://${ES_HOST}/shakespeare/_bulk" \
     --data-binary @sample.json \
     -H 'Content-Type: application/json'
     


# Add an intentionally empty index
curl --silent \
     -X PUT "http://${ES_HOST}/empty_index" \
     -H 'Content-Type: application/json' \
     -d @shakespeare_mapping.json

# Check that we got something
curl -X GET "http://${ES_HOST}/shakespeare/_search?size=1"
