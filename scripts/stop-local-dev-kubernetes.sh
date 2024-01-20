#!/usr/bin/env sh

set -o errexit
set -o nounset

if [ "${RUNHUB_IS_DEVBOX_RUN:-'no'}" = 'yes' ]; then
  "$(dirname -- "$0")"/print.sh 'Stopping local dev Kubernetes cluster (if started).'
  k3d cluster delete dev-runhub || true
  "$(dirname -- "$0")"/print.sh 'Stopping Colima Docker daemon (if started).'
  colima delete --force --profile dev-runhub || true
else
  "$(dirname -- "$0")"/devbox-run.sh "$0" "$@"
fi
