#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"

current_cluster="$(kubectl config view --minify \
  --output jsonpath='{.clusters[].name}' 2> /dev/null || true)"

if [ "${current_cluster}" = 'k3d-dev-runhub' ]; then
  "${SCRIPTS_DIR}"/install.sh
fi
