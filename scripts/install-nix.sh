#!/usr/bin/env sh

set -o errexit
set -o nounset
set -o monitor

VERSION='2.18.1'
INSTALLER_VERSION='0.15.1'

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
    https://install.determinate.systems/nix/tag/v"${INSTALLER_VERSION}")"
  echo "${install_script}" | sh -s -- install --no-confirm
  "$(dirname "$0")"/print.sh 'Restart shell to activate Nix.'
}

main() {
  is_installed="$("$(dirname "$0")"/is-found.sh nix)"
  is_installer_installed="$("$(dirname "$0")"/is-found.sh /nix/nix-installer)"

  if [ "${is_installed}" = 'no' ]; then
    "$(dirname "$0")"/confirm.sh 'Nix not found, install with Determinate Nix Installer?'
    install
  else
    current_version="$(get_current_version)"
    is_updated="$("$(dirname "$0")"/is-version-greater-equal.sh "${current_version}" "${VERSION}")"

    if [ "${is_updated}" = 'no' ]; then
      "$(dirname "$0")"/confirm.sh \
        'Nix outdated, update to v'"${VERSION}"' (uninstall & reinstall) with Determinate Nix Installer?'
      install
    else
      if [ "${is_installer_installed}" = 'yes' ]; then
        current_installer_version="$(get_current_installer_version)"
        is_installer_updated="$("$(dirname "$0")"/is-version-greater-equal.sh \
          "${current_installer_version}" "${INSTALLER_VERSION}")"

        if [ "${is_installer_updated}" = 'no' ]; then
          "$(dirname "$0")"/confirm.sh \
            'Determinate Nix Installer outdated, update to v'"${INSTALLER_VERSION}"' (uninstall & reinstall)?'
          install
        fi
      fi
    fi
  fi
}

main "$@"
