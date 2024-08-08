#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
devbox_shellenv="$("${scripts_dir}"/devbox-shellenv.sh)"
eval "${devbox_shellenv}"

"${scripts_dir}"/stop-dev-cluster.sh
echo 'Stopping dev runhub docker.'
colima stop --profile dev-runhub
