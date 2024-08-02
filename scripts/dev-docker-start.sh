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

is_instance_config_equal() (
  instance_confg="$(echo "$1" | yq --exit-status '.instance.config.'"$2")"

  if [ "${instance_confg}" = "$3" ]; then
    echo true
  else
    echo false
  fi
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
  host_cpus="$(getconf _NPROCESSORS_CONF)"
  host_memory_gibibytes="$("${scripts_dir}"/get-memory-gibibytes.sh)"
  half_host_memory_gibibytes="$(echo "${host_memory_gibibytes}"' / 2' | bc)"

  if [ "${dev_docker}" ]; then
    is_colima_version_equal="$(is_instance_config_equal "${dev_docker}" 'env.RUNHUB_COLIMA_VERSION' "${colima_version}")"

    if ! "${is_colima_version_equal}"; then
      colima delete --force --profile dev-runhub > /dev/null 2>&1
    else
      is_cpus_equal="$(is_instance_config_equal "${dev_docker}" 'cpus' "${host_cpus}")"
      is_memory_equal="$(is_instance_config_equal "${dev_docker}" 'memory' "${half_host_memory_gibibytes}GiB")"

      if ! "${is_cpus_equal}" || ! "${is_memory_equal}"; then
        colima stop --profile dev-runhub > /dev/null 2>&1
      fi
    fi
  fi

  colima start --profile dev-runhub --env RUNHUB_COLIMA_VERSION="${colima_version}" \
    --cpu "${host_cpus}" --memory "${half_host_memory_gibibytes}"
)

main "$@"
