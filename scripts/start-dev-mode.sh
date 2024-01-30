#!/usr/bin/env sh

set -o errexit
set -o nounset

"$(dirname "$0")"/print.sh 'Starting dev mode.'
"$(dirname "$0")"/start-local-dev-cluster.sh
