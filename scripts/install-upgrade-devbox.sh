#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"

minimum_required_version='0.13.7'
nixpkgs_commit='71a6392e367b08525ee710a93af2e80083b5b3e2'

is_installed_upgraded() {
  if command -v devbox >/dev/null; then
    installed_version="$(devbox version)"
    "${scripts_dir}"/is-version-greater-equal.sh \
      "${installed_version}" "${minimum_required_version}"
  else
    echo 'no'
  fi
}

install_upgrade() {
  installed_packages="$(nix profile list --json)"

  if echo "${installed_packages}" | grep -Eq '"devbox":'; then
    nix profile upgrade devbox --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
  else
    nix profile install nixpkgs#devbox \
      --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
  fi
}

main() {
  . "${scripts_dir}"/run-nix-daemon.sh
  is_installed_upgraded="$(is_installed_upgraded)"

  if [ "${is_installed_upgraded}" = 'no' ]; then
    "${scripts_dir}"/confirm.sh \
      'Install/Upgrade Devbox v'"${minimum_required_version}"' with `nix profile`?'
    install_upgrade
    was_installed_upgraded="$(is_installed_upgraded)"

    if [ "${was_installed_upgraded}" = 'no' ]; then
      echo 'Devbox v'"${minimum_required_version}"' or higher is required.'
      exit 1
    fi
  fi
}

main "$@"
