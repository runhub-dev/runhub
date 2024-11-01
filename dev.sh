#!/bin/sh

set -o errexit
set -o nounset

runhub_dir="$(dirname "$0")"
scripts_dir="${runhub_dir}"/scripts

. "${scripts_dir}"/run-nix-daemon.sh
"${scripts_dir}"/install-nix.sh
. "${scripts_dir}"/run-nix-daemon.sh
"${scripts_dir}"/install-devbox.sh
"${scripts_dir}"/install-direnv.sh
. "${scripts_dir}"/load-envrc.sh
