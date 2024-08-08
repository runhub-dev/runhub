#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"

"${scripts_dir}"/devbox.sh shellenv --init-hook --install --no-refresh-alias
