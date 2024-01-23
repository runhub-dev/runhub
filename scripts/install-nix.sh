#!/usr/bin/env sh

if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

set -o errexit
set -o nounset
set -o monitor

version='2.18.1'
installer_version='0.15.1'
installer_url=https://install.determinate.systems/nix/tag/v"${installer_version}"

is_installer_installed() {
  [ -f /nix/nix-installer ]
}

get_version() {
  nix --version | cut -d ' ' -f 3
}

get_installer_version() {
  /nix/nix-installer --version | cut -d ' ' -f 2
}

is_updated() {
  "$(dirname "$0")"/is-version-greater-equal.sh "$(get_version)" "${version}"
}

is_installer_updated() {
  "$(dirname "$0")"/is-version-greater-equal.sh "$(get_installer_version)" "${installer_version}"
}

install() {
  curl --proto '=https' --tlsv1.2 -sSf -L "${installer_url}" | sh -s -- install --no-confirm
}

update() {
  if is_installer_installed; then
    /nix/nix-installer uninstall --no-confirm
  fi

  install
}

if ! "$(dirname "$0")"/is-installed.sh 'nix'; then
  "$(dirname "$0")"/confirm.sh 'Nix not found, install with Determinate Nix Installer?'
  install
elif ! is_updated; then
  "$(dirname "$0")"/confirm.sh \
    'Nix outdated, update to v'"${version}"' (uninstall & reinstall) with Determinate Nix Installer?'
  update
elif is_installer_installed; then
  if ! is_installer_updated; then
    "$(dirname "$0")"/confirm.sh \
      'Determinate Nix Installer outdated, update to v'"${installer_version}"' (uninstall & reinstall)?'
    update
  fi
fi
