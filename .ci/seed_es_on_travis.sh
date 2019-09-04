#!/bin/bash

# failure is a natural part of life
set -e

# set up some parameters
ES_HOST=http://127.0.0.1:9200
SLEEP_TIL_STARTUP_SECONDS=20

# where can you get ES binaries?
ES1_ARCHIVE=https://download.elasticsearch.org/elasticsearch/elasticsearch
ES2_ARCHIVE=https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch
ES5PLUS_ARCHIVE=https://artifacts.elastic.co/downloads/elasticsearch

# where is the test data? what file has the mapping for the test "shakespeare" index?
TEST_DATA_DIR=$(pwd)/test_data
LEGACY_MAPPING_FILE="${TEST_DATA_DIR}/legacy_shakespeare_mapping.json"
ES5_MAPPING_FILE="${TEST_DATA_DIR}/es5_shakespeare_mapping.json"
ES6_MAPPING_FILE="${TEST_DATA_DIR}/es6_shakespeare_mapping.json"
ES7_MAPPING_FILE="${TEST_DATA_DIR}/es7_shakespeare_mapping.json"

case "$ES_VERSION" in
    "") ;;

    "1.0.0")
      export MAPPING_FILE=${LEGACY_MAPPING_FILE};
      export ES_BINARY_URL="${ES1_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "1.4.4")
      export MAPPING_FILE=${LEGACY_MAPPING_FILE};
      export ES_BINARY_URL="${ES1_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "1.7.2")
      export MAPPING_FILE=${LEGACY_MAPPING_FILE};
      export ES_BINARY_URL="${ES1_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "2.0.2")
      export MAPPING_FILE=${LEGACY_MAPPING_FILE};
      export ES_BINARY_URL="${ES2_ARCHIVE}/$ES_VERSION/elasticsearch-$ES_VERSION.deb"
      ;;

    "2.1.2")
      export MAPPING_FILE=${LEGACY_MAPPING_FILE};
      export ES_BINARY_URL="${ES2_ARCHIVE}/$ES_VERSION/elasticsearch-$ES_VERSION.deb"
      ;;

    "2.2.2")
      export MAPPING_FILE=${LEGACY_MAPPING_FILE};
      export ES_BINARY_URL="${ES2_ARCHIVE}/$ES_VERSION/elasticsearch-$ES_VERSION.deb"
      ;;

    "2.3.5")
      export MAPPING_FILE=${LEGACY_MAPPING_FILE};
      export ES_BINARY_URL="${ES2_ARCHIVE}/$ES_VERSION/elasticsearch-$ES_VERSION.deb"
      ;;

    "5.0.2")
      export MAPPING_FILE=${ES5_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "5.3.3")
      export MAPPING_FILE=${ES5_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "5.4.3")
      export MAPPING_FILE=${ES5_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "5.6.9")
      export MAPPING_FILE=${ES5_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "6.0.1")
      export MAPPING_FILE=${ES6_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "6.1.4")
      export ES_VERSION=6.1.4;
      export MAPPING_FILE=${ES6_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "6.2.4")
      export MAPPING_FILE=${ES6_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION.deb"
      ;;

    "7.3.1")
      export MAPPING_FILE=${ES7_MAPPING_FILE};
      export ES_BINARY_URL="${ES5PLUS_ARCHIVE}/elasticsearch-$ES_VERSION-amd64.deb"
      ;;
   esac

# pull the binary
curl ${ES_BINARY_URL} \
    --output elasticsearch.deb

# start the service and wait a bit
sudo dpkg \
    -i \
    --force-confnew \
    elasticsearch.deb

# deal with permissions
# reference: https://discuss.elastic.co/t/permission-denied-starting-elasticsearch-7-0/179336
sudo chown -R \
    elasticsearch:elasticsearch \
    /etc/default/elasticsearch

sudo service elasticsearch start
sleep ${SLEEP_TIL_STARTUP_SECONDS}
sudo service elasticsearch status

# seed ES with data
mv ${MAPPING_FILE} shakespeare_mapping.json
echo $(ls)

curl -X PUT \
    "${ES_HOST}/shakespeare" \
    --silent \
    -H 'Content-Type:application/json' \
    -d @shakespeare_mapping.json

curl -X PUT \
    "${ES_HOST}/empty_index" \
    --silent \
    -H 'Content-Type:application/json' \
    -d @shakespeare_mapping.json

mv test_data/sample.json sample.json

curl -X POST \
    "${ES_HOST}/shakespeare/_bulk" \
    --silent \
    -H 'Content-Type:application/json' \
    --data-binary @sample.json

# test that the expected data made it
curl -X POST \
    "${ES_HOST}/_refresh"

curl -X GET \
    "${ES_HOST}/shakespeare/_search?size=1" \
    -H 'Content-Type:application/json'
