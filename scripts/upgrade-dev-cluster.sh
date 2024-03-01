#!/usr/bin/env sh

set -o errexit
set -o nounset

runhub_dir="$(dirname "$0")"/..
current_context="$(kubectl config view --minify 2> /dev/null || true)"

if [ "${current_context}" ]; then
  current_cluster="$(echo "${current_context}" | yq --exit-status '.clusters[].name')"
fi

if [ "${current_cluster:-''}" = 'k3d-dev-runhub' ]; then
  echo 'Upgrading runhub.'
  helm upgrade \
    --namespace runhub runhub-operator \
    "${runhub_dir}"/charts/runhub-operator \
    --set repository=file:///runhub --set revision="$(git rev-parse --verify HEAD)" > /dev/null
fi
