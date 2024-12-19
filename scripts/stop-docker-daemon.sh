#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
. "${scripts_dir}"/docker-daemon.sh
. "${scripts_dir}"/docker-context.sh

runhub_dir="${scripts_dir}"/.. . "${scripts_dir}"/load-envrc.sh
docker_daemon="$(get_docker_daemon)"

if [ -n "${docker_daemon}" ]; then
  docker_daemon_status="$(echo "${docker_daemon}" | yq '.instance.status' --exit-status)"

  if [ "${docker_daemon_status}" != 'Stopped' ]; then
    stop_docker_daemon
  fi
fi

is_current_docker_context_set="$(is_current_docker_context_set)"

if [ "${is_current_docker_context_set}" = 'yes' ]; then
  unset_current_docker_context
fi

has_docker_context="$(has_docker_context)"

if [ "${has_docker_context}" = 'yes' ]; then
  remove_docker_context
fi
