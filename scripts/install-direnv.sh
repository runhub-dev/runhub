#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..
version='2.34.0'

append_if_not_found() {
  if ! grep -Fs "$1" "$2" > /dev/null; then
    printf '\n%s\n' "$1" >> "$2"
  fi
}

install() {
  devbox global add direnv@"${version}" > /dev/null 2>&1

  devbox_global_shellenv_script="$(devbox global shellenv --recompute 2> /dev/null)"
  eval "${devbox_global_shellenv_script}"
  devbox_global_direnv_path="$(command -v direnv)"
  devbox_global_bin_path="$(dirname "${devbox_global_direnv_path}")"

  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.bashrc
  append_if_not_found 'PATH='"${devbox_global_bin_path}"':"${PATH}"' ~/.zshrc
  append_if_not_found 'eval "$(direnv hook bash)"' ~/.bashrc
  append_if_not_found 'eval "$(direnv hook zsh)"' ~/.zshrc
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
    "${scripts_dir}"/confirm.sh 'direnv not found, install with Devbox Global?'
    install
  else
    current_version="$(direnv version)"
    is_updated="$("${scripts_dir}"/is-version-greater-equal.sh "${current_version}" "${version}")"

    if ! "${is_updated}"; then
      "${scripts_dir}"/confirm.sh 'direnv outdated, update to v'"${version}"' with Devbox Global?'
      update
    fi
  fi

  status_output="$(cd "${runhub_dir}" && direnv status)"

  if ! echo "${status_output}" | grep -F 'Found RC allowed 0' > /dev/null; then
    direnv allow "${runhub_dir}"
  fi
}

main "$@"
