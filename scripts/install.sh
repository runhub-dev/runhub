#!/usr/bin/env sh

set -o errexit
set -o nounset

SCRIPTS_DIR="$(dirname "$0")"
RUNHUB_DIR="${SCRIPTS_DIR}"/..

get_release() {
  helm list --deployed --short --namespace "$1" --filter ^"$2"$
}

argo_cd_release="$(get_release argocd argo-cd)"

if ! [ "${argo_cd_release}" ]; then
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

runhub_operator_release="$(get_release runhub runhub-operator)"

if ! [ "${runhub_operator_release}" ]; then
  echo 'Installing runhub.'
else
  echo 'Upgrading runhub.'
fi

helm upgrade --install --create-namespace --namespace runhub \
  runhub-operator "${RUNHUB_DIR}"/charts/runhub-operator \
  --set repoURL="$(git remote get-url origin)" --set revision="$(git rev-parse --verify HEAD)" \
  > /dev/null

if ! [ "${runhub_operator_release}" ]; then
  echo 'Waiting until runhub is ready.'

  while [ "${status:-}" != 'Healthy' ]; do
    status="$(kubectl get ApplicationSet --namespace argocd runhub --output yaml 2> /dev/null \
      | yq '.status.applicationStatus.[] | select(.application == "argo-cd") | .status')"
    sleep 1
  done
fi
