#!/usr/bin/env sh

set -o errexit
set -o nounset

VERSION='2.33.0'

is_installed_with_devbox_global() {
  path="$(command -v direnv)"
  devbox_global_path="$(devbox global path 2> /dev/null)"

  if [ "${path}" != "${path#"${devbox_global_path}"}" ]; then
    echo 'yes'
  else
    echo 'no'
  fi
}

get_current_version() {
  direnv version
}

install() {
  "$(dirname "$0")"/hide-unless-error.sh devbox global add direnv@"${VERSION}"
  devbox_global_shellenv_script="$(devbox global shellenv)"
  eval "${devbox_global_shellenv_script}"
  devbox_global_bin_path="$(dirname "$(command -v direnv)")"
  "$(dirname "$0")"/append-if-not-found.sh 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.bashrc
  "$(dirname "$0")"/append-if-not-found.sh 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.zshrc
  "$(dirname "$0")"/append-if-not-found.sh 'eval "$(direnv hook bash)"' ~/.bashrc
  "$(dirname "$0")"/append-if-not-found.sh 'eval "$(direnv hook zsh)"' ~/.zshrc
  "$(dirname "$0")"/print.sh 'Restart shell to activate direnv.'
}

update() {
  is_installed_with_devbox_global="$(is_installed_with_devbox_global)"

  if [ "${is_installed_with_devbox_global}" = 'no' ]; then
    "$(dirname "$0")"/print.sh \
      'direnv cannot be updated because it was not installed with Devbox Global, either uninstall it or update it.'
    exit 1
  fi

  install
}

is_allowed_for_runhub() {
  runhub_status_output="$(cd "$(dirname "$0")"/.. && direnv status)"

  if echo "${runhub_status_output}" | grep -Fq 'Found RC allowed 0'; then
    echo 'yes'
  else
    echo 'no'
  fi
}

allow_for_runhub() {
  direnv allow "$(dirname "$0")"/..
}

main() {
  is_installed="$("$(dirname "$0")"/is-found.sh direnv)"

  if [ "${is_installed}" = 'no' ]; then
    "$(dirname "$0")"/confirm.sh 'direnv not found, install with Devbox Global?'
    install
  else
    is_updated="$("$(dirname "$0")"/is-version-greater-equal.sh \
      "$(get_current_version)" "${VERSION}")"

    if [ "${is_updated}" = 'no' ]; then
      "$(dirname "$0")"/confirm.sh 'direnv outdated, update to v'"${VERSION}"' with Devbox Global?'
      update
    fi
  fi

  is_allowed_for_runhub="$(is_allowed_for_runhub)"

  if [ "${is_allowed_for_runhub}" = 'no' ]; then
    allow_for_runhub
  fi
}

main "$@"
