#!/bin/bash

set -e

echo "collecting arguments..."

DEFAULT_VERSION="6.2"
MAJOR_VERSION=${1:-$DEFAULT_VERSION}
echo "major version: $MAJOR_VERSION"

WDIR=$(pwd)
TESTDIR=${WDIR}/sandbox
SAMPLE_DATA_FILE=$(pwd)/test-data/sample.json
ES_HOST="127.0.0.1"

echo "Starting up Elasticsearch..."

case "${MAJOR_VERSION}" in

1.0) docker run -d -p 9200:9200 barnybug/elasticsearch:1.0.0
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
1.4) docker run -d -p 9200:9200 barnybug/elasticsearch:1.4.4
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
1.7) docker run -d -p 9200:9200 barnybug/elasticsearch:1.7.2
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
2.0) docker run -d -p 9200:9200 docker.elastic.co/elasticsearch/elasticsearch:2.0.2
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
2.1) docker run -d -p 9200:9200 docker.elastic.co/elasticsearch/elasticsearch:2.1.2
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
2.2) docker run -d -p 9200:9200 docker.elastic.co/elasticsearch/elasticsearch:2.2.2
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
2.3) docker run -d -p 9200:9200 docker.elastic.co/elasticsearch/elasticsearch:2.3.5
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
2.4) docker run -d -p 9200:9200 docker.elastic.co/elasticsearch/elasticsearch:2.4.6
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
5.0) docker run -d -p 9200:9200 \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:5.0.2
     MAPPING_FILE=$(pwd)/test-data/es5_shakespeare_mapping.json
    ;;
5.3) docker run -d -p 9200:9200 \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:5.3.3
     MAPPING_FILE=$(pwd)/test-data/es5_shakespeare_mapping.json
    ;;
5.4) docker run -d -p 9200:9200 \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:5.4.3
     MAPPING_FILE=$(pwd)/test-data/es5_shakespeare_mapping.json
    ;;
5.5) docker run -d -p 9200:9200 \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:5.5.3
     MAPPING_FILE=$(pwd)/test-data/es5_shakespeare_mapping.json
    ;;
5.6) docker run -d -p 9200:9200 \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:5.6.16
     MAPPING_FILE=$(pwd)/test-data/es5_shakespeare_mapping.json
    ;;
6.0) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:6.0.1
     MAPPING_FILE=$(pwd)/test-data/es6_shakespeare_mapping.json
    ;;
6.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:6.1.4
     MAPPING_FILE=$(pwd)/test-data/es6_shakespeare_mapping.json
    ;;
6.2) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:6.2.4
     MAPPING_FILE=$(pwd)/test-data/es6_shakespeare_mapping.json
    ;;
6.8) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:6.8.2
     MAPPING_FILE=$(pwd)/test-data/es6_shakespeare_mapping.json
     ;;
7.3) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.3.1
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
*) echo "Did not recognize version ${MAJOR_VERSION}. Not starting Elasticsearch"
   exit 1
   ;;
esac

echo "Elasticsearch v${MAJOR_VERSION} is now running on localhost:9200"

echo "Setting up local testing environment"

# Creating testing directory
mkdir -p ${TESTDIR}

# Get data
cp ${MAPPING_FILE} ${TESTDIR}/shakespeare_mapping.json
cp ${SAMPLE_DATA_FILE} ${TESTDIR}/sample.json
cd ${TESTDIR}

# give the cluster a chance
sleep 15

# Create shakespeare index and shakespeare mapping
curl -X PUT "http://${ES_HOST}:9200/shakespeare" \
     -H 'Content-Type: application/json' \
     -d @shakespeare_mapping.json

# Upload data
curl -X POST "http://${ES_HOST}:9200/shakespeare/_bulk" \
     -H 'Content-Type: application/json' \
     --data-binary @sample.json

# Add an intentionally empty index
curl -X PUT "http://${ES_HOST}:9200/empty_index" \
     -H 'Content-Type: application/json' \
     -d @shakespeare_mapping.json

# Refresh all indices
curl -X POST "http://${ES_HOST}:9200/_refresh"

# Check that we got something
curl -X GET "http://${ES_HOST}:9200/shakespeare/_search?size=1"

cd ${WDIR}

echo ""
echo "Your local environment is ready!"
