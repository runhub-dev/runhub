#!/usr/bin/env sh

set -o errexit
set -o nounset

version='2.33.0'

is_installed() {
  command -v direnv > /dev/null 2>&1
}

is_installed_with_devbox_global() {
  path="$(command -v direnv)"
  devbox_global_path="$(devbox global path 2> /dev/null)"
  [ "${path}" != "${path#"${devbox_global_path}"}" ]
}

get_version() {
  direnv version
}

is_minimum_required_version() {
  "$(dirname "$0")"/is-version-greater-equal.sh "$(get_version)" "${version}"
}

append_if_not_found() {
  if ! [ -f "$2" ] || ! grep -Fq "$1" "$2"; then
    printf '\n%s\n' "$1" >> "$2"
  fi
}

install() {
  output="$(devbox global add direnv@"${version}" 2>&1)" || exit_status="$?"

  if [ "${exit_status:-0}" != 0 ]; then
    "$(dirname "$0")"/print.sh "${output}"
    exit "${exit_status}"
  fi

  eval "$(devbox global shellenv)"
  devbox_global_bin_path="$(dirname "$(command -v direnv)")"
  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.bashrc
  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.zshrc
  append_if_not_found 'eval "$(direnv hook bash)"' ~/.bashrc
  append_if_not_found 'eval "$(direnv hook zsh)"' ~/.zshrc
  "$(dirname "$0")"/print.sh 'Restart shell to activate direnv.'
}

update() {
  if ! is_installed_with_devbox_global; then
    "$(dirname "$0")"/print.sh \
      'direnv cannot be updated because it was not installed with Devbox Global, either uninstall it or update it.'
    exit 1
  fi

  install
}

is_allowed_for_runhub() {
  (cd "$(dirname "$0")"/.. && direnv status) | grep -Fq 'Found RC allowed 0'
}

allow_for_runhub() {
  direnv allow "$(dirname "$0")"/..
}

if ! is_installed; then
  "$(dirname "$0")"/confirm.sh 'direnv not found, install with Devbox Global?'
  install
elif ! is_minimum_required_version; then
  "$(dirname "$0")"/confirm.sh 'direnv outdated, update to v'"${version}"' with Devbox Global?'
  update
fi

if ! is_allowed_for_runhub; then
  allow_for_runhub
fi
