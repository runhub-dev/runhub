#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
version='0.11.0'
launcher_version='0.2.2'

get_current_version() {
  current_version_grep="$(echo "$2" | grep '^'"$1"':')"
  current_version_tr="$(echo "${current_version_grep}" | tr -s ' ')"
  echo "${current_version_tr}" | cut -d ' ' -f 2
}

main() {
  if ! command -v devbox > /dev/null; then
    "${scripts_dir}"/confirm.sh 'Devbox not found, install?'
    install_script="$(curl -fsSL https://get.jetify.com/devbox)"
    echo "${install_script}" | bash -s -- --force
  else
    current_version_output="$(devbox version --quiet --verbose)"
    current_version="$(get_current_version 'Version' "${current_version_output}")"
    is_updated="$("${scripts_dir}"/is-version-greater-equal.sh "${current_version}" "${version}")"
    current_launcher_version="$(get_current_version 'Launcher' "${current_version_output}")"
    is_launcher_updated="$("${scripts_dir}"/is-version-greater-equal.sh \
      "${current_launcher_version}" "${launcher_version}")"

    if ! "${is_updated}" || ! "${is_launcher_updated}"; then
      "${scripts_dir}"/confirm.sh 'Devbox outdated, update?'
      devbox version update
    fi
  fi
}

main "$@"
