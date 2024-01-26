#!/usr/bin/env sh

set -o errexit
set -o nounset
set -o monitor

version='2.18.1'
installer_version='0.15.1'

get_current_version() {
  current_version_output="$(nix --version)"
  echo "${current_version_output}" | cut -d ' ' -f 3
}

get_current_installer_version() {
  current_installer_version_output="$(/nix/nix-installer --version)"
  echo "${current_installer_version_output}" | cut -d ' ' -f 2
}

install() {
  if [ "${is_installer_installed}" = 'yes' ]; then
    /nix/nix-installer uninstall --no-confirm
  fi

  install_script="$(curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix/tag/v"${installer_version}")"
  echo "${install_script}" | sh -s -- install --no-confirm
  "$(dirname "$0")"/print.sh 'Restart shell to activate nix.'
}

is_installed="$("$(dirname "$0")"/is-found.sh nix)"
is_installer_installed="$("$(dirname "$0")"/is-found.sh /nix/nix-installer)"

if [ "${is_installed}" = 'no' ]; then
  "$(dirname "$0")"/confirm.sh 'Nix not found, install with Determinate Nix Installer?'
  install
else
  current_version="$(get_current_version)"
  is_updated="$("$(dirname "$0")"/is-version-greater-equal.sh "${current_version}" "${version}")"

  if [ "${is_updated}" = 'no' ]; then
    "$(dirname "$0")"/confirm.sh \
      'Nix outdated, update to v'"${version}"' (uninstall & reinstall) with Determinate Nix Installer?'
    install
  else
    if [ "${is_installer_installed}" = 'yes' ]; then
      current_installer_version="$(get_current_installer_version)"
      is_installer_updated="$("$(dirname "$0")"/is-version-greater-equal.sh \
        "${current_installer_version}" "${installer_version}")"

      if [ "${is_installer_updated}" = 'no' ]; then
        "$(dirname "$0")"/confirm.sh \
          'Determinate Nix Installer outdated, update to v'"${installer_version}"' (uninstall & reinstall)?'
        install
      fi
    fi
  fi
fi
