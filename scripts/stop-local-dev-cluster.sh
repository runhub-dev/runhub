#!/usr/bin/env sh

set -o errexit
set -o nounset

is_colima_docker_daemon_running="$(colima list --json --profile dev-runhub)"

if [ "${is_colima_docker_daemon_running}" ]; then
  echo 'Stopping Colima Docker daemon and local dev Kubernetes cluster in Docker.'
  colima delete --force --profile dev-runhub
fi

if k3d cluster get dev-runhub > /dev/null 2>&1; then
  echo 'Stopping local dev Kubernetes cluster in Docker.'
  k3d cluster delete dev-runhub
fi
