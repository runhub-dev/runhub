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

install() {
  curl --proto '=https' --tlsv1.2 -sSf -L "${installer_url}" | sh -s -- install --no-confirm
}

update() {
  if is_installer_installed; then
    /nix/nix-installer uninstall --no-confirm
  fi

  install
}

is_installed="$("$(dirname "$0")"/is-installed.sh 'nix')"

if [ "${is_installed}" = 'no' ]; then
  "$(dirname "$0")"/confirm.sh 'Nix not found, install with Determinate Nix Installer?'
  install
else
  is_updated="$("$(dirname "$0")"/is-version-greater-equal.sh "$(get_version)" "${version}")"

  if [ "${is_updated}" = 'no' ]; then
    "$(dirname "$0")"/confirm.sh \
      'Nix outdated, update to v'"${version}"' (uninstall & reinstall) with Determinate Nix Installer?'
    update
  elif is_installer_installed; then
    is_installer_updated="$("$(dirname "$0")"/is-version-greater-equal.sh \
      "$(get_installer_version)" "${installer_version}")"

    if [ "${is_installer_updated}" = 'no' ]; then
      "$(dirname "$0")"/confirm.sh \
        'Determinate Nix Installer outdated, update to v'"${installer_version}"' (uninstall & reinstall)?'
      update
    fi
  fi
fi
