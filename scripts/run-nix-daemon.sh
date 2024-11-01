#!/bin/sh

set -o errexit
set -o nounset

nix_daemon_script='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

if ! command -v nix > /dev/null; then
  if [ -e "${nix_daemon_script}" ]; then
    echo 'Running `. '"${nix_daemon_script}"'`...'
    set +o nounset
    . "${nix_daemon_script}"
    set -o nounset
  fi
fi
