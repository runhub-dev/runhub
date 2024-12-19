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
trap 'echo ; exit' INT
trap "${scripts_dir}"/stop-docker-daemon.sh EXIT
"${scripts_dir}"/start-docker-daemon.sh
echo 'Press Ctrl+C to exit...'

if [ "${IS_RUNHUB_TEST}" = 'no' ]; then
  sleep 2147483647
fi
