#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..

main() {
  if ! docker version > /dev/null 2>&1; then
    total_number_cpus="$(getconf _NPROCESSORS_CONF)"
    total_gibibytes_memory="$("${SCRIPTS_DIR}"/get-total-gibibytes-memory.sh)"
    half_total_gibibytes_memory="$(echo "${total_gibibytes_memory}"' / 2' | bc)"

    "${SCRIPTS_DIR}"/print.sh 'Docker daemon not running, starting Colima Docker daemon.'
    colima start --profile dev-runhub \
      --cpu "${total_number_cpus}" --memory "${half_total_gibibytes_memory}" --disk 64
  fi

  "${SCRIPTS_DIR}"/print.sh 'Starting local dev Kubernetes cluster in Docker.'
  k3d cluster create --config "${RUNHUB_DIR}"/k3d.yaml
}

if [ "${RUNHUB_IS_DEVBOX_RUN:-'no'}" = 'yes' ]; then
  main "$@"
else
  "${SCRIPTS_DIR}"/devbox-run.sh "$0" "$@"
fi
