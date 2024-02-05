#!/usr/bin/env sh

set -o errexit
set -o nounset

RUNHUB_DIR="$(dirname "$0")"
SCRIPTS_DIR="${RUNHUB_DIR}"/scripts

start_dev_mode() {
  previous_docker_context="$(devbox run docker context show)"
  previous_kube_context="$(devbox run kubectl config current-context 2> /dev/null || true)"
  echo 'Starting dev mode.'
  devbox run --config "${RUNHUB_DIR}" "${SCRIPTS_DIR}"/start-local-dev-cluster.sh
}

stop_dev_mode() {
  echo 'Stopping dev mode.'
  devbox run --config "${RUNHUB_DIR}" "${SCRIPTS_DIR}"/stop-local-dev-cluster.sh
  devbox run docker context use "${previous_docker_context}" > /dev/null 2>&1 || true
  devbox run kubectl config use-context "${previous_kube_context}" > /dev/null 2>&1 || true
}

main() {
  "${SCRIPTS_DIR}"/install-nix.sh
  "${SCRIPTS_DIR}"/install-devbox.sh
  "${SCRIPTS_DIR}"/install-direnv.sh
  trap 'echo ; exit' INT
  trap 'stop_dev_mode' EXIT
  start_dev_mode
  echo 'Press Ctrl+C to stop dev mode.'
  sleep 2147483647
}

main "$@"
