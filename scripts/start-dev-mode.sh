#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"

"${SCRIPTS_DIR}"/print.sh 'Starting dev mode.'
"${SCRIPTS_DIR}"/start-local-dev-cluster.sh
