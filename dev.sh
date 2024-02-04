#!/usr/bin/env sh

set -o errexit
set -o nounset

RUNHUB_DIR="$(dirname "$0")"
SCRIPTS_DIR="${RUNHUB_DIR}"/scripts

start_dev_mode() {
  echo 'Starting dev mode.'
  devbox run --config "${RUNHUB_DIR}" "${SCRIPTS_DIR}"/start-local-dev-cluster.sh
}

stop_dev_mode() {
  echo 'Stopping dev mode.'
  devbox run --config "${RUNHUB_DIR}" "${SCRIPTS_DIR}"/stop-local-dev-cluster.sh
}

main() {
  "${SCRIPTS_DIR}"/install-dependencies.sh
  trap 'echo ; exit' INT
  trap 'stop_dev_mode' EXIT
  start_dev_mode
  echo 'Press Ctrl+C to stop dev mode.'
  sleep 2147483647
}

main "$@"
