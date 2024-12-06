#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..
. "${scripts_dir}"/docker-daemon.sh

. "${scripts_dir}"/load-envrc.sh
docker_daemon="$(get_docker_daemon)"

if [ -n "${docker_daemon}" ]; then
  docker_daemon_status="$(echo "${docker_daemon}" | yq --exit-status '.instance.status')"

  if [ "${docker_daemon_status}" != 'Running' ]; then
    start_docker_daemon
  fi
else
  create_docker_daemon
  start_docker_daemon
fi

echo 'Creating runhub Docker context...'
docker context create runhub \
  --docker host=unix://"${HOME}"/.lima/runhub-docker-daemon/sock/docker.sock || true
echo 'Setting current Docker context to runhub...'
docker context use runhub
