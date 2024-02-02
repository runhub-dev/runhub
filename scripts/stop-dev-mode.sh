#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"

"${SCRIPTS_DIR}"/print.sh 'Stopping dev mode.'
"${SCRIPTS_DIR}"/stop-local-dev-cluster.sh
