#!/usr/bin/env sh

set -o errexit
set -o nounset

RUNHUB_DIR="$(dirname "$0")"
SCRIPTS_DIR="${RUNHUB_DIR}"/scripts

"${SCRIPTS_DIR}"/install-nix.sh
"${SCRIPTS_DIR}"/install-devbox.sh
"${SCRIPTS_DIR}"/install-direnv.sh
direnv exec "${RUNHUB_DIR}" "${SCRIPTS_DIR}"/dev.sh
