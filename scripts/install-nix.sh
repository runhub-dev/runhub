#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
version='2.21.2'
installer_version='0.19.1'

install() (
  if command -v /nix/nix-installer > /dev/null; then
    echo 'Outdated version must be uninstalled before updated version can be installed.'
    /nix/nix-installer uninstall

    if command -v /nix/nix-installer > /dev/null; then
      exit 1
    fi
  fi

  install_script="$(curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix/tag/v"${installer_version}")"
  echo "${install_script}" | sh -s -- install

  if ! command -v /nix/nix-installer > /dev/null; then
    exit 1
  fi
)

is_updated() (
  current_version_output="$(/nix/var/nix/profiles/default/bin/nix --version)"
  current_version="$(echo "${current_version_output}" | cut -d ' ' -f 3)"
  "${scripts_dir}"/is-version-greater-equal.sh "${current_version}" "${version}"
)

is_installer_updated() (
  current_installer_version_output="$(/nix/nix-installer --version)"
  current_installer_version="$(echo "${current_installer_version_output}" | cut -d ' ' -f 2)"
  "${scripts_dir}"/is-version-greater-equal.sh "${current_installer_version}" "${installer_version}"
)

main() (
  if ! command -v /nix/var/nix/profiles/default/bin/nix > /dev/null; then
    install
  else
    is_updated="$(is_updated)"

    if ! "${is_updated}"; then
      install
    else
      if command -v /nix/nix-installer > /dev/null; then
        is_installer_updated="$(is_installer_updated)"

        if ! "${is_installer_updated}"; then
          install
        fi
      fi
    fi
  fi
)

main "$@"
