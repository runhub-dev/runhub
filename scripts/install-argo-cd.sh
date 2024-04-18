#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

echo 'Installing Argo CD.'
chart_yaml="$(helm template "${runhub_dir}"/charts/runhub \
  --values "${runhub_dir}"/runhub-infra.yaml)"
app_yaml="$(echo "${chart_yaml}" | yq --exit-status '
  select(.kind == "ApplicationSet" and .metadata.name == "runhub").spec.generators.[] |
  select(.list).list.elements.[] | select(.metadata.name == "argo-cd")')"
version="$(echo "${app_yaml}" | yq --exit-status '.spec.source.targetRevision')"
values="$(echo "${app_yaml}"  | yq --exit-status '.spec.source.helm.values')"
echo "${values}" | helm upgrade --install --create-namespace \
  --namespace argocd argocd \
  --repo https://argoproj.github.io/argo-helm argo-cd --version "${version}" \
  --values - > /dev/null
