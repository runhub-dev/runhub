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

  if [ "${docker_daemon_status}" != 'Stopped' ]; then
    stop_docker_daemon
  fi
fi

echo 'Removing runhub Docker context...'
docker context remove --force runhub
