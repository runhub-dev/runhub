#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname -- "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..

devbox run --config "${RUNHUB_DIR}" --env RUNHUB_IS_DEVBOX_RUN='yes' -- "$@"
