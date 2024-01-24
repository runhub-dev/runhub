#!/usr/bin/env sh

set -o errexit
set -o nounset

version='0.8.7'
launcher_version='0.2.1'

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

update() {
  devbox version update
}

is_installed="$("$(dirname "$0")"/is-installed.sh 'devbox')"

if [ "${is_installed}" = 'no' ]; then
  "$(dirname "$0")"/confirm.sh 'Devbox not found, install?'
  install
else
  current_version="$(get_current_version 'Version')"
  is_updated="$("$(dirname "$0")"/is-version-greater-equal.sh \
    "${current_version}" "${version}")"
  current_launcher_version="$(get_current_version 'Launcher')"
  is_launcher_updated="$("$(dirname "$0")"/is-version-greater-equal.sh \
    "${current_launcher_version}" "${launcher_version}")"

  if [ "${is_updated}" = 'no' ] || [ "${is_launcher_updated}" = 'no' ]; then
    "$(dirname "$0")"/confirm.sh 'Devbox outdated, update?'
    update
  fi
fi
