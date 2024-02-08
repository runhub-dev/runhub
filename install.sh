#!/usr/bin/env sh

set -o errexit
set -o nounset

RUNHUB_DIR="$(dirname "$0")"
SCRIPTS_DIR="${RUNHUB_DIR}"/scripts

"${SCRIPTS_DIR}"/direnv-exec.sh "${SCRIPTS_DIR}"/install.sh
