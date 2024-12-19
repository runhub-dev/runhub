#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

. "${scripts_dir}"/load-envrc.sh
echo 'Running `shellcheck`...'
find -L "${runhub_dir}" \
  ! \( -path '*/.git/*' -o -path '*/.devbox/*' \) -a \
  \( -name '*.sh' -o -name '.envrc' \) -a \
  -exec shellcheck {} +
