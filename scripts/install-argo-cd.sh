#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

echo 'Installing Argo CD.'
namespace_chart_yaml="$(helm template --namespace argocd argocd "${runhub_dir}"/charts/namespace)"
runhub_chart_yaml="$(helm template --namespace runhub runhub "${runhub_dir}"/charts/runhub \
  --values "${runhub_dir}"/runhub-infra.yaml)"
argo_cd_app_source_yaml="$(echo "${runhub_chart_yaml}" | yq --exit-status '
  select(.kind == "ApplicationSet" and .metadata.name == "runhub").spec.generators.[] |
  select(.list).list.elements.[] |
  select(.metadata.name == "argo-cd").spec.sources.[] |
  select(.chart == "argo-cd")')"
argo_cd_version="$(echo "${argo_cd_app_source_yaml}" | yq --exit-status '.targetRevision')"
argo_cd_values="$(echo "${argo_cd_app_source_yaml}"  | yq --exit-status '.helm.values')"
argo_cd_chart_yaml="$(echo "${argo_cd_values}" | helm template --namespace argocd argocd \
  --repo https://argoproj.github.io/argo-helm argo-cd --version "${argo_cd_version}" --values -)"
combined_chart_yaml="$(printf '%s\n%s' "${namespace_chart_yaml}" "${argo_cd_chart_yaml}")"
labeled_chart_yaml="$(echo "${combined_chart_yaml}" | yq '
  select(.kind != "CustomResourceDefinition")
  .metadata.labels += {"argocd.argoproj.io/instance": "argo-cd"}')"
echo "${labeled_chart_yaml}" | kubectl apply --filename - > /dev/null
