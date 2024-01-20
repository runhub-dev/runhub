#!/usr/bin/env sh

set -o errexit
set -o nounset

devbox run --config "$(dirname -- "$0")"/.. --env RUNHUB_IS_DEVBOX_RUN='yes' "$@"
