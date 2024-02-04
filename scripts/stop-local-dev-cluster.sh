#!/usr/bin/env sh

set -o errexit
set -o nounset

is_colima_docker_daemon_running() {
  colima_docker_daemon="$(colima list --json --profile dev-runhub)"

  if [ "${colima_docker_daemon}" ]; then
    echo 'yes'
  else
    echo 'no'
  fi
}

main() {
  is_colima_docker_daemon_running="$(is_colima_docker_daemon_running)"

  if [ "${is_colima_docker_daemon_running}" = 'yes' ]; then
    echo 'Stopping Colima Docker daemon and local dev Kubernetes cluster in Docker.'
    colima delete --force --profile dev-runhub
  fi

  if k3d cluster list dev-runhub > /dev/null 2>&1; then
    echo 'Stopping local dev Kubernetes cluster in Docker.'
    k3d cluster delete dev-runhub
  fi
}

main "$@"
