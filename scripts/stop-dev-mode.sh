#!/usr/bin/env sh

set -o errexit
set -o nounset

"$(dirname "$0")"/print.sh 'Stopping dev mode.'
"$(dirname "$0")"/stop-local-dev-cluster.sh
