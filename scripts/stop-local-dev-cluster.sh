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

is_local_dev_cluster_running() {
  if k3d cluster list dev-runhub > /dev/null 2>&1; then
    echo 'yes'
  else
    echo 'no'
  fi
}

main() {
  is_colima_docker_daemon_running="$(is_colima_docker_daemon_running)"

  if [ "${is_colima_docker_daemon_running}" = 'yes' ]; then
    "$(dirname -- "$0")"/print.sh \
      'Stopping Colima Docker daemon and local dev Kubernetes cluster in Docker.'
    colima delete --force --profile dev-runhub
  fi

  is_local_dev_cluster_running="$(is_local_dev_cluster_running)"

  if [ "${is_local_dev_cluster_running}" = 'yes' ]; then
    "$(dirname -- "$0")"/print.sh 'Stopping local dev Kubernetes cluster in Docker.'
    k3d cluster delete dev-runhub
  fi
}

if [ "${RUNHUB_IS_DEVBOX_RUN:-'no'}" = 'yes' ]; then
  main "$@"
else
  "$(dirname -- "$0")"/devbox-run.sh "$0" "$@"
fi
