#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

. "${scripts_dir}"/load-envrc.sh
echo 'Stopping Docker daemon...'
docker_daemon_status="$("${scripts_dir}"/get-docker-daemon.sh '.instance.status')"

if [ -n "${docker_daemon_status}" ] && [ "${docker_daemon_status}" != 'Stopped' ]; then
  limactl stop runhub-docker-daemon
fi

echo 'Removing Docker context...'
docker context remove --force runhub
