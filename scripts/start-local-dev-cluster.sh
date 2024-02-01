#!/usr/bin/env sh

set -o errexit
set -o nounset

is_docker_daemon_running() {
  if docker version > /dev/null 2>&1; then
    echo 'yes'
  else
    echo 'no'
  fi
}

main() {
  is_docker_daemon_running="$(is_docker_daemon_running)"

  if [ "${is_docker_daemon_running}" = 'no' ]; then
    total_number_cpus="$(getconf _NPROCESSORS_CONF)"
    total_gibibytes_memory="$("$(dirname -- "$0")"/get-total-gibibytes-memory.sh)"
    half_total_gibibytes_memory="$(echo "${total_gibibytes_memory}"' / 2' | bc)"

    "$(dirname -- "$0")"/print.sh 'Docker daemon not running, starting Colima Docker daemon.'
    colima start --profile dev-runhub \
      --cpu "${total_number_cpus}" --memory "${half_total_gibibytes_memory}" --disk 64
  fi

  "$(dirname -- "$0")"/print.sh 'Starting local dev Kubernetes cluster in Docker.'
  k3d cluster create --config "$(dirname -- "$0")"/../k3d.yaml
}

if [ "${RUNHUB_IS_DEVBOX_RUN:-'no'}" = 'yes' ]; then
  main "$@"
else
  "$(dirname -- "$0")"/devbox-run.sh "$0" "$@"
fi
