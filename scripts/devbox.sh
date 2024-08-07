#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..
devbox_flake='nixpkgs/6e14bbce7bea6c4efd7adfa88a40dac750d80100#devbox'
"${scripts_dir}"/install-nix.sh
nix run "${devbox_flake}" -- --config "${runhub_dir}" "$@"
