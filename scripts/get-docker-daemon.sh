#!/bin/sh

set -o errexit
set -o nounset

docker_daemon="$(limactl --log-level error list --format yaml runhub-docker-daemon || true)"

if [ -n "${docker_daemon}" ]; then
  echo "${docker_daemon}" | yq --exit-status "$1"
fi
