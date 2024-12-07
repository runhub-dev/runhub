#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"

minimum_required_version='0.13.6'
nixpkgs_commit='226216574ada4c3ecefcbbec41f39ce4655f78ef'

is_installed_upgraded() {
  if command -v devbox > /dev/null; then
    installed_version="$(devbox version)"
    "${scripts_dir}"/is-version-greater-equal.sh \
      "${installed_version}" "${minimum_required_version}"
  else
    echo 'no'
  fi
}

install_upgrade() {
  nix profile remove devbox --quiet --quiet
  nix profile install nixpkgs#devbox \
    --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
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
