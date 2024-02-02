#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname -- "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..

"${SCRIPTS_DIR}"/install-nix.sh
"${SCRIPTS_DIR}"/install-devbox.sh
"${SCRIPTS_DIR}"/install-direnv.sh
"${SCRIPTS_DIR}"/direnv-allow.sh "${RUNHUB_DIR}"
