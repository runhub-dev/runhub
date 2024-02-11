#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..

template="$(helm template runhub "${RUNHUB_DIR}"/charts/runhub)"
argo_cd="$(echo "${template}" | yq --exit-status '
  select(.kind == "ApplicationSet" and .metadata.name == "runhub").spec.generators.[] |
  select(.list).list.elements.[] | select(.name == "argo-cd")')"
argo_cd_version="$(echo "${argo_cd}" | yq --exit-status '.targetRevision')"
argo_cd_values="$(echo "${argo_cd}" | yq --exit-status '.values')"
echo 'Installing Argo CD and waiting until ready.'
echo "${argo_cd_values}" | helm install --wait --create-namespace --namespace argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm argo-cd --version "${argo_cd_version}" \
  --values - > /dev/null
echo 'Installing runhub.'
helm install --create-namespace --namespace runhub \
  runhub-operator "${RUNHUB_DIR}"/charts/runhub-operator \
  --set repoURL="$(git remote get-url origin)" --set revision="$(git rev-parse --verify HEAD)" \
  > /dev/null
echo 'Waiting until runhub is ready.'

while [ "${status:-}" != 'Healthy' ]; do
  status="$(kubectl get ApplicationSet --namespace argocd runhub --output yaml 2> /dev/null \
    | yq '.status.applicationStatus.[] | select(.application == "argo-cd") | .status')"
  sleep 1
done
