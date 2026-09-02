#!/bin/bash

set -e

echo "collecting arguments..."

ES_VERSION=${1}
echo "Elasticsearch version: $ES_VERSION"

WDIR=$(pwd)
TESTDIR=${WDIR}/sandbox
SAMPLE_DATA_FILE=$(pwd)/test-data/sample.json
ES_HOST="127.0.0.1"
ES_PORT="9200"

echo "Starting up Elasticsearch..."

case "${ES_VERSION}" in

1.7.6)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" elasticsearch:1.7.6
    MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
2.4.6)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" elasticsearch:2.4.6
    MAPPING_FILE=$(pwd)/test-data/legacy_shakespeare_mapping.json
    ;;
5.6.16)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:5.6.16
    MAPPING_FILE=$(pwd)/test-data/es5_shakespeare_mapping.json
    ;;
6.8.15)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:6.8.15
    MAPPING_FILE=$(pwd)/test-data/es6_shakespeare_mapping.json
    ;;
7.0.1)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:7.0.1
    MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
    SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
7.17.22)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:7.17.22
    MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
    SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
8.0.1)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:8.0.1
    MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
    SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
8.5.3)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:8.5.3
    MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
    SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
8.10.4)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:8.10.4
    MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
    SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
8.15.5)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:8.15.5
    MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
    SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
8.17.2)
    docker run --rm -d --name uptasticsearch -p "${ES_PORT}:9200" \
        -e "discovery.type=single-node" \
        -e "xpack.security.enabled=false" \
        docker.elastic.co/elasticsearch/elasticsearch:8.17.2
    MAPPING_FILE=$(pwd)/test-data/es7_shakespeare_mapping.json
    SAMPLE_DATA_FILE=$(pwd)/test-data/sample_es7.json
    ;;
*)
    echo "Did not recognize version ${ES_VERSION}. Not starting Elasticsearch"
    exit 1
    ;;
esac

echo "Elasticsearch v${ES_VERSION} is now running at http://${ES_HOST}:9200"

echo "Setting up local testing environment"

# Creating testing directory
mkdir -p "${TESTDIR}"

# Get data
cp "${MAPPING_FILE}" "${TESTDIR}/shakespeare_mapping.json"
cp "${SAMPLE_DATA_FILE}" "${TESTDIR}/sample.json"
cd "${TESTDIR}"

# wait for the cluster to be reachable (max 5 minutes)
echo "waiting for Elasticsearch to come up..."
SECONDS=0
until curl -s -I --show-error "http://${ES_HOST}:9200" > /dev/null 2>&1; do
    if ((SECONDS >= 30)); then
        echo "Elasticsearch did not become reachable within 30 seconds" >&2
        echo ""
        echo "--- docker ps ---"
        echo ""
        docker logs uptasticsearch
        echo ""
        echo "--- docker logs ---"
        echo ""
        docker logs uptasticsearch
        exit 1
    fi
    echo "not up, sleeping 5 seconds"
    sleep 5
done
echo "Elasticsearch is up (after ${SECONDS}s), seeding test data"

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

cd "${WDIR}"

echo ""
echo "Your local environment is ready."
