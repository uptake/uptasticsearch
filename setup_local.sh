#!/bin/bash

set -e

echo "collecting arguments..."

ES_VERSION=${1}
echo "Elasticsearch version: $ES_VERSION"

WDIR=$(pwd)
TESTDIR=${WDIR}/sandbox
SAMPLE_DATA_FILE=$(pwd)/test-data/sample.json
ES_HOST="127.0.0.1"

echo "Starting up Elasticsearch..."

case "${ES_VERSION}" in

1.0.3) docker run -d -p 9200:9200 barnybug/elasticsearch:1.0.3
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
1.7.6) docker run -d -p 9200:9200 elasticsearch:1.7.6
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
2.4.6) docker run -d -p 9200:9200 elasticsearch:2.4.6
     MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
5.6.16) docker run -d -p 9200:9200 \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:5.6.16
     MAPPING_FILE=$(pwd)/test-data/es5_shakespeare_mapping.json
    ;;
6.0.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:6.0.1
     MAPPING_FILE=$(pwd)/test-data/es6_shakespeare_mapping.json
    ;;
6.8.15) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:6.8.11
     MAPPING_FILE=$(pwd)/test-data/es6_shakespeare_mapping.json
     ;;
7.0.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.0.1
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.1.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.1.1
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.2.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.2.1
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.3.2) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.3.2
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.4.2) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.4.2
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.5.2) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.5.2
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.6.2) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.6.2
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.7.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.7.1
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
     ;;
7.8.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.8.1
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
7.9.3) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.9.3
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
7.10.2) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.10.2
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
7.11.2) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.11.2
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
7.12.1) docker run -d -p 9200:9200 \
          -e "discovery.type=single-node" \
          -e "xpack.security.enabled=false" \
          docker.elastic.co/elasticsearch/elasticsearch:7.12.1
     MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
     SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
*) echo "Did not recognize version ${ES_VERSION}. Not starting Elasticsearch"
   exit 1
   ;;
esac

echo "Elasticsearch v${ES_VERSION} is now running at http://${ES_HOST}:9200"

echo "Setting up local testing environment"

# Creating testing directory
mkdir -p ${TESTDIR}

# Get data
cp ${MAPPING_FILE} ${TESTDIR}/shakespeare_mapping.json
cp ${SAMPLE_DATA_FILE} ${TESTDIR}/sample.json
cd ${TESTDIR}

# give the cluster a chance
sleep 30

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
echo "Your local environment is ready."
