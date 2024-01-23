#!/usr/bin/env sh

set -o errexit
set -o nounset

version='0.8.6'
launcher_version='0.2.1'

get_version() {
  devbox version --quiet --verbose | grep '^'"$1"':' | tr -s ' ' | cut -d ' ' -f 2
}

is_minimum_required_version() {
  "$(dirname "$0")"/is-version-greater-equal.sh "$(get_version 'Version')" "${version}"
}

is_minimum_required_launcher_version() {
  "$(dirname "$0")"/is-version-greater-equal.sh "$(get_version 'Launcher')" "${launcher_version}"
}

install() {
  curl -fsSL https://get.jetpack.io/devbox | bash -s -- --force
}

update() {
  devbox version update
}

if ! "$(dirname "$0")"/is-installed.sh 'devbox'; then
  "$(dirname "$0")"/confirm.sh 'Devbox not found, install?'
  install
elif ! is_minimum_required_version || ! is_minimum_required_launcher_version; then
  "$(dirname "$0")"/confirm.sh 'Devbox outdated, update?'
  update
fi
