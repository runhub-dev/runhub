#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..
runhub_absolute_dir="$(cd "${runhub_dir}" && pwd)"

if [ "${DEVBOX_PROJECT_ROOT:-}" != "${runhub_absolute_dir}" ]; then
  devbox_shellenv="$("${scripts_dir}"/devbox.sh shellenv --init-hook --install --no-refresh-alias)"
  eval "${devbox_shellenv}"
fi
