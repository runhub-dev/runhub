#!/bin/sh

set -o errexit
set -o nounset

get_docker_daemon() {
  lima_instances=$(limactl --log-level error list --format yaml)

  if [ -n "${lima_instances}" ]; then
    echo "${lima_instances}" | yq 'select(.instance.name == "runhub-docker-daemon")'
  fi
}

create_docker_daemon() {
  echo 'Creating runhub Docker daemon...'
  limactl --tty=false create --name runhub-docker-daemon template://docker-rootful
}

start_docker_daemon() {
  echo 'Starting runhub Docker daemon...'
  limactl start runhub-docker-daemon
}

stop_docker_daemon() {
  echo 'Stopping runhub Docker daemon...'
  limactl stop runhub-docker-daemon
}
