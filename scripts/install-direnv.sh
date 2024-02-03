#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"
VERSION='2.33.0'

get_devbox_global_bin_path() {
  devbox_global_shellenv_script="$(devbox global shellenv --recompute 2> /dev/null)"
  eval "${devbox_global_shellenv_script}"
  devbox_global_direnv_path="$(command -v direnv)"
  dirname "${devbox_global_direnv_path}"
}

install() {
  "${SCRIPTS_DIR}"/hide-unless-error.sh devbox global add direnv@"${VERSION}"
  devbox_global_bin_path="$(get_devbox_global_bin_path)"
  "${SCRIPTS_DIR}"/append-if-not-found.sh 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.bashrc
  "${SCRIPTS_DIR}"/append-if-not-found.sh 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.zshrc
  "${SCRIPTS_DIR}"/append-if-not-found.sh 'eval "$(direnv hook bash)"' ~/.bashrc
  "${SCRIPTS_DIR}"/append-if-not-found.sh 'eval "$(direnv hook zsh)"' ~/.zshrc
  "${SCRIPTS_DIR}"/print.sh 'Restart shell to activate direnv.'
}

is_installed_with_devbox_global() {
  direnv_path="$(command -v direnv)"
  devbox_global_path="$(devbox global path 2> /dev/null)"

  if [ "${direnv_path}" != "${direnv_path#"${devbox_global_path}"}" ]; then
    echo 'yes'
  else
    echo 'no'
  fi
}

update() {
  is_installed_with_devbox_global="$(is_installed_with_devbox_global)"

  if [ "${is_installed_with_devbox_global}" = 'no' ]; then
    "${SCRIPTS_DIR}"/print.sh \
      'direnv cannot be updated because it was not installed with Devbox Global, either uninstall it or update it.'
    exit 1
  fi

  install
}

main() {
  is_installed="$("${SCRIPTS_DIR}"/is-found.sh direnv)"

  if [ "${is_installed}" = 'no' ]; then
    "${SCRIPTS_DIR}"/confirm.sh 'direnv not found, install with Devbox Global?'
    install
  else
    current_version="$(direnv version)"
    is_updated="$("${SCRIPTS_DIR}"/is-version-greater-equal.sh "${current_version}" "${VERSION}")"

    if [ "${is_updated}" = 'no' ]; then
      "${SCRIPTS_DIR}"/confirm.sh 'direnv outdated, update to v'"${VERSION}"' with Devbox Global?'
      update
    fi
  fi
}

main "$@"
