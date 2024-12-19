#!/bin/sh

set -o errexit
set -o nounset

has_docker_context() {
  docker_contexts="$(docker context list --quiet)"

  if echo "${docker_contexts}" | grep -Eq '^runhub$'; then
    echo 'yes'
  else
    echo 'no'
  fi
}

create_docker_context() {
  echo 'Creating runhub Docker context...'
  docker context create runhub \
    --docker host=unix://"${HOME}"/.lima/runhub-docker-daemon/sock/docker.sock
}

is_current_docker_context_set() {
  current_docker_context_name="$(docker context show)"

  if [ "${current_docker_context_name}" = 'runhub' ]; then
    echo 'yes'
  else
    echo 'no'
  fi
}

set_current_docker_context() {
  echo 'Setting current Docker context to runhub...'
  docker context use runhub
}

unset_current_docker_context() {
  echo 'Setting current Docker context to default...'
  docker context use default
}

remove_docker_context() {
  echo 'Removing runhub Docker context...'
  docker context remove runhub
}
