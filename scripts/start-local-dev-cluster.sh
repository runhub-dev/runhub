#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..

get_total_gibibytes_memory() {
  darwin_memory_output="$(sysctl -n hw.memsize 2> /dev/null || true)"

  if [ "${darwin_memory_output}" ]; then
    echo "${darwin_memory_output}"' / 1024^3' | bc
  else
    linux_memory_output="$(cat /proc/meminfo 2> /dev/null || true)"

    if [ "${linux_memory_output}" ]; then
      linux_memory_output_grep="$(echo "${linux_memory_output}" | grep '^MemTotal:')"
      linux_memory_output_tr="$(echo "${linux_memory_output_grep}" | tr -s ' ')"
      linux_memory_output_cut="$(echo "${linux_memory_output_tr}" | cut -d ' ' -f 2)"
      echo "${linux_memory_output_cut}"' / 1024^2 + 1' | bc
    else
      exit 1
    fi
  fi
}

main() {
  if ! docker version > /dev/null 2>&1; then
    total_number_cpus="$(getconf _NPROCESSORS_CONF)"
    total_gibibytes_memory="$(get_total_gibibytes_memory)"
    half_total_gibibytes_memory="$(echo "${total_gibibytes_memory}"' / 2' | bc)"

    echo 'Docker daemon not running, starting Colima Docker daemon.'
    colima start --profile dev-runhub \
      --cpu "${total_number_cpus}" --memory "${half_total_gibibytes_memory}" --disk 64
  fi

  echo 'Starting local dev Kubernetes cluster in Docker.'
  k3d cluster create --config "${RUNHUB_DIR}"/k3d.yaml
}

main "$@"
