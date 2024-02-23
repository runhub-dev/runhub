#!/usr/bin/env sh

set -o errexit
set -o nounset

runhub_dir="$(dirname "$0")"/..
current_cluster="$(kubectl config view --minify \
  --output jsonpath='{.clusters[].name}' 2> /dev/null || true)"

if [ "${current_cluster}" = 'k3d-dev-runhub' ]; then
  echo 'Upgrading runhub.'
  helm upgrade --namespace runhub runhub-operator "${runhub_dir}"/charts/runhub-operator \
    --set repository=file:///runhub --set revision="$(git rev-parse --verify HEAD)" > /dev/null
fi
