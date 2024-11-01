#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"

minimum_required_version='0.13.4'
nixpkgs_commit='d4f247e89f6e10120f911e2e2d2254a050d0f732'

install() {
  "${scripts_dir}"/confirm.sh \
    'Install Devbox v'"${minimum_required_version}"' with `nix profile install nixpkgs#devbox`?'
  nix profile install nixpkgs#devbox \
    --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
}

is_upgraded() {
  installed_version="$(devbox version)"
  "${scripts_dir}"/is-version-greater-equal.sh "${installed_version}" "${minimum_required_version}"
}

upgrade() {
  "${scripts_dir}"/confirm.sh \
    'Upgrade to Devbox v'"${minimum_required_version}"' with `nix profile upgrade devbox`?'
  nix profile upgrade devbox --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
}

main() {
  if ! command -v devbox > /dev/null; then
    install
  else
    is_upgraded="$(is_upgraded)"

    if [ "${is_upgraded}" = 'false' ]; then
      upgrade
    fi
  fi
}

main "$@"
