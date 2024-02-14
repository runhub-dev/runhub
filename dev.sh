#!/usr/bin/env sh

set -o errexit
set -o nounset

runhub_dir="$(dirname "$0")"
scripts_dir="${runhub_dir}"/scripts

"${scripts_dir}"/install-nix.sh
"${scripts_dir}"/install-devbox.sh
"${scripts_dir}"/install-direnv.sh

if ! command -v nix > /dev/null || ! command -v direnv > /dev/null; then
  echo 'Restart shell and rerun to complete install and continue.'
  exit 1
fi

direnv exec "${runhub_dir}" "${scripts_dir}"/dev.sh
