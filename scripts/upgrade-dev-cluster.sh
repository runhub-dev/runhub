#!/usr/bin/env sh

set -o errexit
set -o nounset

current_cluster="$(kubectl config view --minify \
  --output jsonpath='{.clusters[].name}' 2> /dev/null || true)"

if [ "${current_cluster}" = 'k3d-dev-runhub' ]; then
  echo 'Upgrading runhub.'
  helm upgrade --namespace runhub runhub-operator "${RUNHUB_DIR}"/charts/runhub-operator \
    --set repoURL=file:///runhub --set revision="$(git rev-parse --verify HEAD)" > /dev/null
fi
