#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
version='2.21.2'
installer_version='0.18.0'

install() {
  (
    set -o monitor

    if command -v /nix/nix-installer > /dev/null; then
      /nix/nix-installer uninstall --no-confirm
    fi

    install_script="$(curl --proto '=https' --tlsv1.2 -sSf -L \
      https://install.determinate.systems/nix/tag/v"${installer_version}")"
    echo "${install_script}" | sh -s -- install --no-confirm
  )
}

main() {
  if ! command -v nix > /dev/null; then
    "${scripts_dir}"/confirm.sh 'Nix not found, install with Determinate Nix Installer?'
    install
  else
    current_version_output="$(nix --version)"
    current_version="$(echo "${current_version_output}" | cut -d ' ' -f 3)"
    is_updated="$("${scripts_dir}"/is-version-greater-equal.sh "${current_version}" "${version}")"

    if ! "${is_updated}"; then
      "${scripts_dir}"/confirm.sh \
        'Nix outdated, update to v'"${version}"' (uninstall & reinstall) with Determinate Nix Installer?'
      install
    else
      if command -v /nix/nix-installer > /dev/null; then
        current_installer_version_output="$(/nix/nix-installer --version)"
        current_installer_version="$(echo "${current_installer_version_output}" | cut -d ' ' -f 2)"
        is_installer_updated="$("${scripts_dir}"/is-version-greater-equal.sh \
          "${current_installer_version}" "${installer_version}")"

        if ! "${is_installer_updated}"; then
          "${scripts_dir}"/confirm.sh \
            'Determinate Nix Installer outdated, update to v'"${installer_version}"' (uninstall & reinstall)?'
          install
        fi
      fi
    fi
  fi
}

main "$@"
