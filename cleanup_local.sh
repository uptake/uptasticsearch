#!/bin/bash

set -e 

# Remove testing directory
echo "removing testing directory"
rm -r $(pwd)/sandbox

# Kill the running container
echo "killing running container"
docker kill $(docker ps -ql)

echo "done cleaning up test environment"
