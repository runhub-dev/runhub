#!/usr/bin/env sh

set -o errexit
set -o nounset

RUNHUB_DIR="$(dirname "$0")"
SCRIPTS_DIR="${RUNHUB_DIR}"/scripts

"${SCRIPTS_DIR}"/install-nix.sh
"${SCRIPTS_DIR}"/install-devbox.sh
"${SCRIPTS_DIR}"/install-direnv.sh

if ! command -v nix > /dev/null || ! command -v direnv > /dev/null; then
  echo 'Restart shell and rerun to complete install and continue.'
  exit 1
fi

direnv exec "${RUNHUB_DIR}" "${SCRIPTS_DIR}"/dev.sh
