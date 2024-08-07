#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
devbox_shellenv="$("${scripts_dir}"/devbox.sh shellenv --init-hook --install --no-refresh-alias)"
eval "${devbox_shellenv}"
