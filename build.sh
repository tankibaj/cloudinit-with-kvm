#!/usr/bin/env bash

# Error Handling
set -o errexit
set -o pipefail
set -o nounset

./master/build.sh
./worker-01/build.sh