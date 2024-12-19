#!/bin/sh

set -o errexit
set -o nounset

export IS_RUNHUB_TEST="${IS_RUNHUB_TEST:-no}"

runhub_dir="$(dirname "$0")"
scripts_dir="${runhub_dir}"/scripts

. "${scripts_dir}"/run-nix-daemon.sh
"${scripts_dir}"/install-upgrade-nix.sh
. "${scripts_dir}"/run-nix-daemon.sh
"${scripts_dir}"/install-upgrade-devbox.sh
"${scripts_dir}"/install-upgrade-direnv.sh
. "${scripts_dir}"/load-envrc.sh
"${scripts_dir}"/run-shellcheck.sh
"${scripts_dir}"/run-shfmt.sh
