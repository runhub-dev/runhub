#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"

start() {
  previous_docker_context="$(docker context show)"
  previous_kube_context="$(kubectl config current-context 2> /dev/null || true)"
  "${SCRIPTS_DIR}"/start-local-dev-cluster.sh
}

stop() {
  "${SCRIPTS_DIR}"/stop-local-dev-cluster.sh
  docker context use "${previous_docker_context}" > /dev/null 2>&1 || true
  kubectl config use-context "${previous_kube_context}" > /dev/null 2>&1 || true
}

main() {
  trap 'echo ; exit' INT
  trap 'stop' EXIT
  start
  echo 'Press Ctrl+C to stop.'
  sleep 2147483647
}

main "$@"
