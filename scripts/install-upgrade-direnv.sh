#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

minimum_required_version='2.35.0'
nixpkgs_commit='71a6392e367b08525ee710a93af2e80083b5b3e2'

is_installed_upgraded() {
  if command -v direnv >/dev/null; then
    installed_version="$(direnv version)"
    "${scripts_dir}"/is-version-greater-equal.sh \
      "${installed_version}" "${minimum_required_version}"
  else
    echo 'no'
  fi
}

install_upgrade() {
  installed_packages="$(nix profile list --json)"

  if echo "${installed_packages}" | grep -Eq '"direnv":'; then
    nix profile upgrade direnv --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
  else
    nix profile install nixpkgs#direnv \
      --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
  fi
}

append_if_not_found() {
  if ! grep -Fqs "$1" "$2"; then
    echo 'Adding `'"$1"'` to '"$2"'...'
    printf '\n%s\n' "$1" >>"$2"
  fi
}

add_to_shells() {
  append_if_not_found 'eval "$(direnv hook bash)"' "${HOME}"/.bashrc
  append_if_not_found 'eval "$(direnv hook zsh)"' "${HOME}"/.zshrc
  mkdir -p "${HOME}"/.config/fish
  append_if_not_found 'direnv hook fish | source' "${HOME}"/.config/fish/config.fish
}

run_allow() {
  status="$(cd "${runhub_dir}" && direnv status)"

  if echo "${status}" | grep -Eq '^Found RC allowed 1$'; then
    echo 'Running `direnv allow`...'
    direnv allow "${runhub_dir}"
  fi
}

main() {
  . "${scripts_dir}"/run-nix-daemon.sh
  is_installed_upgraded="$(is_installed_upgraded)"

  if [ "${is_installed_upgraded}" = 'no' ]; then
    "${scripts_dir}"/confirm.sh \
      'Install/Upgrade direnv v'"${minimum_required_version}"' with `nix profile`?'
    install_upgrade
    was_installed_upgraded="$(is_installed_upgraded)"

    if [ "${was_installed_upgraded}" = 'no' ]; then
      echo 'direnv v'"${minimum_required_version}"' or higher is required.'
      exit 1
    fi
  fi

  add_to_shells
  run_allow
}

main "$@"
