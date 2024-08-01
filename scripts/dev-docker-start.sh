#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"

get_dev_docker() (
  colima_template="$(colima template --print)"
  colima_template_dir="$(dirname "${colima_template}")"
  colima_lima_dir="${colima_template_dir}"/../_lima
  LIMA_HOME="${LIMA_HOME:-"${colima_lima_dir}"}" \
    limactl list colima-dev-runhub --format yaml 2> /dev/null || true
)

get_instance_config() (
  echo "$1" | yq --exit-status '.instance.config.'"$2"
)

get_colima_version() (
  colima_version_output="$(colima version)"
  colima_version_head="$(echo "${colima_version_output}" | head -n 1)"
  echo "${colima_version_head}" | cut -d ' ' -f 3
)

main() (
  . "${scripts_dir}"/devbox-shellenv.sh
  echo 'Starting dev runhub docker.'
  dev_docker="$(get_dev_docker)"
  colima_version="$(get_colima_version)"
  total_number_cpus="$(getconf _NPROCESSORS_CONF)"
  total_gibibytes_memory="$("${scripts_dir}"/get-total-gibibytes-memory.sh)"
  half_total_gibibytes_memory="$(echo "${total_gibibytes_memory}"' / 2' | bc)"

  if [ "${dev_docker}" ]; then
    dev_docker_colima_version="$(get_instance_config "${dev_docker}" 'env.RUNHUB_COLIMA_VERSION')"

    if [ "${dev_docker_colima_version}" != "${colima_version}" ]; then
      colima delete --force --profile dev-runhub > /dev/null 2>&1
    else
      dev_docker_total_number_cpus="$(get_instance_config "${dev_docker}" 'cpus')"
      dev_docker_total_gibibytes_memory="$(get_instance_config "${dev_docker}" 'memory')"

      if [ "${dev_docker_total_number_cpus}" != "${total_number_cpus}" ] \
        || [ "${dev_docker_total_gibibytes_memory}" != "${half_total_gibibytes_memory}GiB" ]; then
        colima stop --profile dev-runhub > /dev/null 2>&1
      fi
    fi
  fi

  colima start --profile dev-runhub --env RUNHUB_COLIMA_VERSION="${colima_version}" \
    --cpu "${total_number_cpus}" --memory "${half_total_gibibytes_memory}"
)

main "$@"
