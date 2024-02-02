#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname -- "$0")"
VERSION='0.9.0'
LAUNCHER_VERSION='0.2.1'

get_current_version() {
  current_version_output="$(devbox version --quiet --verbose)"
  current_version_grep="$(echo "${current_version_output}" | grep '^'"$1"':')"
  current_version_tr="$(echo "${current_version_grep}" | tr -s ' ')"
  echo "${current_version_tr}" | cut -d ' ' -f 2
}

install() {
  install_script="$(curl -fsSL https://get.jetpack.io/devbox)"
  echo "${install_script}" | bash -s -- --force
}

main() {
  is_installed="$("${SCRIPTS_DIR}"/is-found.sh devbox)"

  if [ "${is_installed}" = 'no' ]; then
    "${SCRIPTS_DIR}"/confirm.sh 'Devbox not found, install?'
    install
  else
    current_version="$(get_current_version 'Version')"
    is_updated="$("${SCRIPTS_DIR}"/is-version-greater-equal.sh "${current_version}" "${VERSION}")"
    current_launcher_version="$(get_current_version 'Launcher')"
    is_launcher_updated="$("${SCRIPTS_DIR}"/is-version-greater-equal.sh \
      "${current_launcher_version}" "${LAUNCHER_VERSION}")"

    if [ "${is_updated}" = 'no' ] || [ "${is_launcher_updated}" = 'no' ]; then
      "${SCRIPTS_DIR}"/confirm.sh 'Devbox outdated, update?'
      devbox version update
    fi
  fi
}

main "$@"
