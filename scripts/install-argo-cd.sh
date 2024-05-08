#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

echo 'Installing Argo CD.'
namespace_chart_yaml="$(helm template --namespace argocd argocd "${runhub_dir}"/charts/namespace)"
runhub_chart_yaml="$(helm template --namespace runhub runhub "${runhub_dir}"/charts/runhub \
  --values "${runhub_dir}"/runhub-infra.yaml)"
app_source_yaml="$(echo "${runhub_chart_yaml}" | yq --exit-status '
  select(.kind == "Application" and .metadata.name == "argo-cd").spec.sources.[] |
  select(.chart == "argo-cd")')"
version="$(echo "${app_source_yaml}" | yq --exit-status '.targetRevision')"
values="$(echo "${app_source_yaml}"  | yq --exit-status '.helm.valuesObject')"
chart_yaml="$(echo "${values}" | helm template --namespace argocd argocd \
  --repo https://argoproj.github.io/argo-helm argo-cd --version "${version}" --values -)"
printf '%s\n%s\n' "${namespace_chart_yaml}" "${chart_yaml}" \
  | kubectl apply --filename - > /dev/null
