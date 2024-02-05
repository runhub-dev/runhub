#!/usr/bin/env sh

set -o errexit
set -o nounset

get_colima_docker_daemon="$(colima list --json --profile dev-runhub)"

if [ "${get_colima_docker_daemon=}" ]; then
  echo 'Stopping Colima Docker daemon and local dev Kubernetes cluster in Docker.'
  colima delete --force --profile dev-runhub
fi

if k3d cluster get dev-runhub > /dev/null 2>&1; then
  echo 'Stopping local dev Kubernetes cluster in Docker.'
  k3d cluster delete dev-runhub
fi
