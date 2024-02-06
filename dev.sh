#!/usr/bin/env sh

set -o errexit
set -o nounset

RUNHUB_DIR="$(dirname "$0")"
SCRIPTS_DIR="${RUNHUB_DIR}"/scripts

devbox_run() {
  devbox run --config "${RUNHUB_DIR}" "$@"
}

start() {
  previous_docker_context="$(devbox_run docker context show)"
  previous_kube_context="$(devbox_run kubectl config current-context 2> /dev/null || true)"
  devbox_run "${SCRIPTS_DIR}"/start-local-dev-cluster.sh
}

stop() {
  devbox_run "${SCRIPTS_DIR}"/stop-local-dev-cluster.sh
  devbox_run docker context use "${previous_docker_context}" > /dev/null 2>&1 || true
  devbox_run kubectl config use-context "${previous_kube_context}" > /dev/null 2>&1 || true
}

main() {
  "${SCRIPTS_DIR}"/install-nix.sh
  "${SCRIPTS_DIR}"/install-devbox.sh
  "${SCRIPTS_DIR}"/install-direnv.sh
  trap 'echo ; exit' INT
  trap 'stop' EXIT
  start
  echo 'Press Ctrl+C to stop.'
  sleep 2147483647
}

main "$@"
