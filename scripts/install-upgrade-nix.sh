#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"

minimum_required_version='2.24.10'
minimum_required_installer_version='0.30.0'

get_installed_version() {
  installed_version_stdout="$(nix --version)"
  echo "${installed_version_stdout}" | sed -n -e 's/^nix (Nix) \(.*\)$/\1/p'
}

get_installed_installer_version() {
  installed_installer_version_stdout="$(/nix/nix-installer --version)"
  echo "${installed_installer_version_stdout}" | sed -n -e 's/^nix-installer \(.*\)$/\1/p'
}

is_installed_upgraded() {
  if command -v nix > /dev/null; then
    installed_version="$(get_installed_version)"
    is_upgraded="$("${scripts_dir}"/is-version-greater-equal.sh \
      "${installed_version}" "${minimum_required_version}")"

    if [ "${is_upgraded}" = 'yes' ]; then
      if command -v /nix/nix-installer > /dev/null; then
        installed_installer_version="$(get_installed_installer_version)"
        "${scripts_dir}"/is-version-greater-equal.sh \
          "${installed_installer_version}" "${minimum_required_installer_version}"
      else
        echo 'yes'
      fi
    else
      echo 'no'
    fi
  else
    echo 'no'
  fi
}

install_upgrade() {
  if command -v /nix/nix-installer > /dev/null; then
    installed_installer_version="$(get_installed_installer_version)"
    can_installer_spilt_receipt="$("${scripts_dir}"/is-version-greater-equal.sh \
      "${installed_installer_version}" '0.28.0')"

    if [ "${can_installer_spilt_receipt}" = 'yes' ]; then
      /nix/nix-installer split-receipt --no-confirm
      /nix/nix-installer uninstall --no-confirm /nix/uninstall-phase1.json
    else
      /nix/nix-installer uninstall --no-confirm
    fi
  fi

  installer_install_script="$(curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix/tag/v"${minimum_required_installer_version}")"
  echo "${installer_install_script}" | sh -s -- install --no-confirm
}

main() {
  . "${scripts_dir}"/run-nix-daemon.sh
  is_installed_upgraded="$(is_installed_upgraded)"

  if [ "${is_installed_upgraded}" = 'no' ]; then
    "${scripts_dir}"/confirm.sh \
      'Install/Upgrade Nix v'"${minimum_required_version}"' with Determinate Nix Installer v'"${minimum_required_installer_version}"'?'
    install_upgrade
    . "${scripts_dir}"/run-nix-daemon.sh
    was_installed_upgraded="$(is_installed_upgraded)"

    if [ "${was_installed_upgraded}" = 'no' ]; then
      echo 'Nix v'"${minimum_required_version}"' or higher is required.'
      exit 1
    fi
  fi
}

main "$@"
