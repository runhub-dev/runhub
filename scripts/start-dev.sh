#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
. "${scripts_dir}"/devbox-shellenv.sh

"${scripts_dir}"/start-dev-cluster.sh
echo 'Starting dev runhub.'
make install
make run
