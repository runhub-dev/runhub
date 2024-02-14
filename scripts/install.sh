#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..

if ! kubectl get Namespace argocd > /dev/null 2>&1; then
  runhub_yaml="$(helm template runhub "${RUNHUB_DIR}"/charts/runhub)"
  argo_cd_yaml="$(echo "${runhub_yaml}" | yq --exit-status '
    select(.kind == "ApplicationSet" and .metadata.name == "runhub").spec.generators.[] |
    select(.list).list.elements.[] | select(.name == "argo-cd")')"
  argo_cd_version="$(echo "${argo_cd_yaml}" | yq --exit-status '.targetRevision')"
  argo_cd_values="$(echo "${argo_cd_yaml}" | yq --exit-status '.values')"
  echo 'Installing Argo CD and waiting until ready.'
  echo "${argo_cd_values}" | helm install --wait --create-namespace --namespace argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm argo-cd --version "${argo_cd_version}" \
    --values - > /dev/null
fi

runhub_namespace="$(kubectl get Namespace runhub 2> /dev/null || true)"
echo 'Installing runhub.'
helm upgrade --install --create-namespace \
  --namespace runhub runhub-operator "${RUNHUB_DIR}"/charts/runhub-operator \
  --set repoURL=file:///runhub --set revision="$(git rev-parse --verify HEAD)" > /dev/null

if ! [ "${runhub_namespace}" ]; then
  echo 'Waiting until runhub is ready.'

  kubectl config use-context k3d-dev-runhub-argocd > /dev/null
  argocd --core app wait runhub > /dev/null
  argocd --core app wait argo-cd > /dev/null
  kubectl config use-context k3d-dev-runhub > /dev/null
fi
