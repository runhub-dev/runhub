#!/usr/bin/env sh

set -o errexit
set -o nounset

is_docker_daemon_running() {
  if docker version > /dev/null 2>&1; then
    echo 'yes'
  else
    echo 'no'
  fi
}

start_docker_daemon() {
  colima start --profile dev-runhub
}

start_kubernetes() {
  k3d cluster create --config "$(dirname -- "$0")"/../k3d.yaml
}

if [ "${RUNHUB_IS_DEVBOX_RUN:-'no'}" = 'yes' ]; then
  is_docker_daemon_running="$(is_docker_daemon_running)"

  if [ "${is_docker_daemon_running}" = 'no' ]; then
    "$(dirname -- "$0")"/print.sh 'Docker daemon not running, starting Colima Docker daemon.'
    start_docker_daemon
  fi

  "$(dirname -- "$0")"/print.sh 'Starting local dev Kubernetes cluster in Docker.'
  start_kubernetes
else
  "$(dirname -- "$0")"/devbox-run.sh "$0" "$@"
fi
