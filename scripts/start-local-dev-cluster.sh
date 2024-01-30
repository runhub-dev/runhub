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

main() {
  is_docker_daemon_running="$(is_docker_daemon_running)"

  if [ "${is_docker_daemon_running}" = 'no' ]; then
    "$(dirname -- "$0")"/print.sh 'Docker daemon not running, starting Colima Docker daemon.'
    colima start --profile dev-runhub
  fi

  "$(dirname -- "$0")"/print.sh 'Starting local dev Kubernetes cluster in Docker.'
  k3d cluster create --config "$(dirname -- "$0")"/../k3d.yaml
}

if [ "${RUNHUB_IS_DEVBOX_RUN:-'no'}" = 'yes' ]; then
  main "$@"
else
  "$(dirname -- "$0")"/devbox-run.sh "$0" "$@"
fi
