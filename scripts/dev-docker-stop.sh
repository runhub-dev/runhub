#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
. "${scripts_dir}"/devbox-shellenv.sh
echo 'Stopping dev runhub docker.'
colima stop --profile dev-runhub
