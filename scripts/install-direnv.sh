#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

minimum_required_version='2.35.0'
nixpkgs_commit='d4f247e89f6e10120f911e2e2d2254a050d0f732'

install() {
  "${scripts_dir}"/confirm.sh \
    'Install direnv v'"${minimum_required_version}"' with `nix profile install nixpkgs#direnv`?'
  nix profile install nixpkgs#direnv \
    --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
}

is_upgraded() {
  installed_version="$(direnv version)"
  "${scripts_dir}"/is-version-greater-equal.sh "${installed_version}" "${minimum_required_version}"
}

upgrade() {
  "${scripts_dir}"/confirm.sh \
    'Upgrade to direnv v'"${minimum_required_version}"' with `nix profile upgrade direnv`?'
  nix profile upgrade direnv --override-flake nixpkgs github:NixOS/nixpkgs/"${nixpkgs_commit}"
}

append_if_not_found() {
  if ! grep -Fqs "$1" "$2"; then
    echo 'Adding `'"$1"'` to '"$2"'...'
    printf '\n%s\n' "$1" >> "$2"
  fi
}

hook_into_shells() {
  append_if_not_found 'eval "$(direnv hook bash)"' "${HOME}"/.bashrc
  append_if_not_found 'eval "$(direnv hook zsh)"' "${HOME}"/.zshrc
  mkdir -p "${HOME}"/.config/fish
  append_if_not_found 'direnv hook fish | source' "${HOME}"/.config/fish/config.fish
}

allow_for_runhub_dir() {
  status="$(cd "${runhub_dir}" && direnv status)"

  if echo "${status}" | grep -q '^Found RC allowed 1$'; then
    echo 'Running `direnv allow`...'
    direnv allow "${runhub_dir}"
  fi
}

main() {
  if ! command -v direnv > /dev/null; then
    install
  else
    is_upgraded="$(is_upgraded)"

    if [ "${is_upgraded}" = 'false' ]; then
      upgrade
    fi
  fi

  hook_into_shells
  allow_for_runhub_dir
}

main "$@"
