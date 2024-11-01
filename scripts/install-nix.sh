#!/bin/sh

set -o errexit
set -o nounset
set -o monitor

scripts_dir="$(dirname "$0")"

minimum_required_version='2.24.10'
installer_version='0.27.1'

install() {
  echo \
    'Installing Nix v'"${minimum_required_version}"' with Determinate Nix Installer v'"${installer_version}"'...'
  installer_install_script="$(curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix/tag/v"${installer_version}")"
  echo "${installer_install_script}" | sh -s -- install
  command -v /nix/nix-installer  > /dev/null
}

is_upgraded() {
  installed_version_output="$(nix --version)"
  installed_version="$(echo "${installed_version_output}" | sed -n -e 's/^nix (Nix) \(.*\)$/\1/p')"
  "${scripts_dir}"/is-version-greater-equal.sh "${installed_version}" "${minimum_required_version}"
}

upgrade() {
  "${scripts_dir}"/confirm.sh \
    'Upgrade to Nix v'"${minimum_required_version}"' with `nix upgrade-nix`?'
  echo '`nix upgrade-nix` needs to run as `root`, attempting to escalate now via `sudo`...'
  sudo -i nix upgrade-nix --nix-store-paths-url \
    https://install.determinate.systems/nix-upgrade/tag/v"${minimum_required_version}"/universal
}

main() {
  if ! command -v nix > /dev/null; then
    install
  else
    is_upgraded="$(is_upgraded)"

    if [ "${is_upgraded}" = 'false' ]; then
      upgrade
    fi
  fi
}

main "$@"
