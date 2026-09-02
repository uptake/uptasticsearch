#!/bin/bash

set -e -u -o pipefail

# Remove testing directory
echo "removing testing directory"
rm -r ./sandbox

# Kill the running container
echo "killing running container"
docker kill -f uptasticsearch
docker rm -f uptasticsearch

echo "done cleaning up test environment"
