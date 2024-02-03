#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"

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
    "${SCRIPTS_DIR}"/print.sh \
      'Stopping Colima Docker daemon and local dev Kubernetes cluster in Docker.'
    colima delete --force --profile dev-runhub
  fi

  if k3d cluster list dev-runhub > /dev/null 2>&1; then
    "${SCRIPTS_DIR}"/print.sh 'Stopping local dev Kubernetes cluster in Docker.'
    k3d cluster delete dev-runhub
  fi
}

if [ "${RUNHUB_IS_DEVBOX_RUN:-'no'}" = 'yes' ]; then
  main "$@"
else
  "${SCRIPTS_DIR}"/devbox-run.sh "$0" "$@"
fi
