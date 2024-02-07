#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..
VERSION='2.33.0'

append_if_not_found() {
  if ! grep -Fs "$1" "$2" > /dev/null; then
    printf '\n%s\n' "$1" >> "$2"
  fi
}

 allow_direnv_for_runhub() {
  status_output="$(cd "${RUNHUB_DIR}" && direnv status)"

  if ! echo "${status_output}" | grep -F 'Found RC allowed 0' > /dev/null; then
    direnv allow "${RUNHUB_DIR}"
  fi
 }

install() {
  devbox global add direnv@"${VERSION}" > /dev/null 2>&1
  devbox_global_shellenv_script="$(devbox global shellenv --recompute 2> /dev/null)"
  eval "${devbox_global_shellenv_script}"
  devbox_global_direnv_path="$(command -v direnv)"
  devbox_global_bin_path="$(dirname "${devbox_global_direnv_path}")"
  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.bashrc
  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.zshrc
  append_if_not_found 'eval "$(direnv hook bash)"' ~/.bashrc
  append_if_not_found 'eval "$(direnv hook zsh)"' ~/.zshrc
  allow_direnv_for_runhub
  echo 'Restart shell and rerun to complete direnv install and continue.'
  exit 1
}

update() {
  direnv_path="$(command -v direnv)"
  devbox_global_path="$(devbox global path 2> /dev/null)"

  if [ "${direnv_path}" = "${direnv_path#"${devbox_global_path}"}" ]; then
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

    if ! "${is_updated}"; then
      "${SCRIPTS_DIR}"/confirm.sh 'direnv outdated, update to v'"${VERSION}"' with Devbox Global?'
      update
    fi
  fi

  allow_direnv_for_runhub
}

main "$@"
