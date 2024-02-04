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

append_if_not_found() {
  if [ -e "$2" ]; then
    grep -Fq "$1" "$2" || is_found="$?" ; is_found="${is_found:-0}"

    if [ "${is_found}" != 1 ]; then
      exit "${is_found}"
    fi
  fi

  printf '\n%s\n' "$1" >> "$2"
}

install() {
  devbox global add direnv@"${VERSION}" > /dev/null 2>&1
  devbox_global_bin_path="$(get_devbox_global_bin_path)"
  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.bashrc
  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.zshrc
  append_if_not_found 'eval "$(direnv hook bash)"' ~/.bashrc
  append_if_not_found 'eval "$(direnv hook zsh)"' ~/.zshrc
  echo 'Restart shell to activate direnv.'
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
    echo \
      'direnv cannot be updated because it was not installed with Devbox Global, either uninstall it or update it.'
    exit 1
  fi

  install
}

main() {
  if ! command -v direnv > /dev/null; then
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
