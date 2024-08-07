#!/bin/sh

set -o errexit
set -o nounset

runhub_dir="$(dirname "$0")"/..
runhub_absolute_dir="$(cd "${runhub_dir}" && pwd)"

if [ "${DEVBOX_PROJECT_ROOT:-}" != "${runhub_absolute_dir}" ]; then
  devbox_shellenv="$(nix run nixpkgs/6e14bbce7bea6c4efd7adfa88a40dac750d80100#devbox -- shellenv \
    --config "${runhub_dir}" --init-hook --install --no-refresh-alias)"
  eval "${devbox_shellenv}"
fi
