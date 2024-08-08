#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..
runhub_absolute_dir="$(cd "${runhub_dir}" && pwd)"

devbox_lock_cksum="$(cksum "${runhub_absolute_dir}"/devbox.lock)"

if [ "${__RUNHUB_DEVBOX_LOCK_CKSUM:-}" != "${devbox_lock_cksum}" ]; then
  "${scripts_dir}"/devbox.sh shellenv --init-hook --install --no-refresh-alias \
    --env __RUNHUB_DEVBOX_LOCK_CKSUM="${devbox_lock_cksum}"
fi
