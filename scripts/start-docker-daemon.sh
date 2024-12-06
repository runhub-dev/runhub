#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

. "${scripts_dir}"/load-envrc.sh
echo 'Starting Docker daemon...'
docker_daemon_status="$("${scripts_dir}"/get-docker-daemon.sh '.instance.status')"


if [ -n "${docker_daemon_status}" ]; then
  if [ "${docker_daemon_status}" != 'Running' ]; then
    limactl start runhub-docker-daemon
  fi
else
  limactl --tty=false start --name runhub-docker-daemon template://docker-rootful
fi

echo 'Creating Docker context...'
docker context create runhub-docker-daemon \
  --docker host=unix://"${HOME}"/.lima/runhub-docker-daemon/sock/docker.sock || true
echo 'Setting current Docker context...'
docker context use runhub-docker-daemon
