#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
devbox_shellenv="$("${scripts_dir}"/devbox-shellenv.sh)"
eval "${devbox_shellenv}"

"${scripts_dir}"/start-dev-cluster.sh
echo 'Starting dev runhub.'
make install
make run
