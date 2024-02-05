#!/usr/bin/env sh

set -o errexit
set -o nounset
set -o monitor

SCRIPTS_DIR="$(dirname "$0")"
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
  if command -v /nix/nix-installer > /dev/null; then
    /nix/nix-installer uninstall --no-confirm
  fi

  install_script="$(curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix/tag/v"${INSTALLER_VERSION}")"
  echo "${install_script}" | sh -s -- install --no-confirm
  echo 'Restart shell to activate Nix.'
}

main() {
  if ! command -v nix > /dev/null; then
    "${SCRIPTS_DIR}"/confirm.sh 'Nix not found, install with Determinate Nix Installer?'
    install
  else
    current_version="$(get_current_version)"
    is_updated="$("${SCRIPTS_DIR}"/is-version-greater-equal.sh "${current_version}" "${VERSION}")"

    if ! "${is_updated}"; then
      "${SCRIPTS_DIR}"/confirm.sh \
        'Nix outdated, update to v'"${VERSION}"' (uninstall & reinstall) with Determinate Nix Installer?'
      install
    else
      if command -v /nix/nix-installer > /dev/null; then
        current_installer_version="$(get_current_installer_version)"
        is_installer_updated="$("${SCRIPTS_DIR}"/is-version-greater-equal.sh \
          "${current_installer_version}" "${INSTALLER_VERSION}")"

        if ! "${is_installer_updated}"; then
          "${SCRIPTS_DIR}"/confirm.sh \
            'Determinate Nix Installer outdated, update to v'"${INSTALLER_VERSION}"' (uninstall & reinstall)?'
          install
        fi
      fi
    fi
  fi
}

main "$@"
