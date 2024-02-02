#!/usr/bin/env sh

set -o errexit
set -o nounset

RUNHUB_DIR="$(dirname -- "$0")"
SCRIPTS_DIR="${RUNHUB_DIR}"/scripts

"${SCRIPTS_DIR}"/install-dependencies.sh
trap 'exit 0' INT
trap '"${SCRIPTS_DIR}"/stop-dev-mode.sh' EXIT
"${SCRIPTS_DIR}"/start-dev-mode.sh
"${SCRIPTS_DIR}"/print.sh 'Press Ctrl+C to stop dev mode.'
sleep 2147483647
