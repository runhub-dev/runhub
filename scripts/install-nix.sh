#!/usr/bin/env sh

if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

set -o errexit
set -o nounset
set -o monitor

version='2.18.1'
installer_version='0.15.1'

is_installer_installed() {
  [ -f /nix/nix-installer ]
}

get_current_version() {
  current_version_output="$(nix --version)"
  echo "${current_version_output}" | cut -d ' ' -f 3
}

get_current_installer_version() {
  current_installer_version_output="$(/nix/nix-installer --version)"
  echo "${current_installer_version_output}" | cut -d ' ' -f 2
}

install() {
  install_script="$(curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix/tag/v"${installer_version}")"
  echo "${install_script}" | sh -s -- install --no-confirm
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
  current_version="$(get_current_version)"
  is_updated="$("$(dirname "$0")"/is-version-greater-equal.sh "${current_version}" "${version}")"

  if [ "${is_updated}" = 'no' ]; then
    "$(dirname "$0")"/confirm.sh \
      'Nix outdated, update to v'"${version}"' (uninstall & reinstall) with Determinate Nix Installer?'
    update
  elif is_installer_installed; then
    current_installer_version="$(get_current_installer_version)"
    is_installer_updated="$("$(dirname "$0")"/is-version-greater-equal.sh \
      "${current_installer_version}" "${installer_version}")"

    if [ "${is_installer_updated}" = 'no' ]; then
      "$(dirname "$0")"/confirm.sh \
        'Determinate Nix Installer outdated, update to v'"${installer_version}"' (uninstall & reinstall)?'
      update
    fi
  fi
fi
