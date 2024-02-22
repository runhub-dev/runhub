#!/usr/bin/env sh

set -o errexit
set -o nounset

runhub_dir="$(dirname "$0")"/..

get_total_gibibytes_memory() {
  darwin_memory_output="$(sysctl -n hw.memsize 2> /dev/null || true)"

  if [ "${darwin_memory_output}" ]; then
    echo "${darwin_memory_output}"' / 1024^3' | bc
  else
    linux_memory_output="$(cat /proc/meminfo 2> /dev/null || true)"

    if [ "${linux_memory_output}" ]; then
      linux_memory_output_grep="$(echo "${linux_memory_output}" | grep '^MemTotal:')"
      linux_memory_output_tr="$(echo "${linux_memory_output_grep}" | tr -s ' ')"
      linux_memory_output_cut="$(echo "${linux_memory_output_tr}" | cut -d ' ' -f 2)"
      echo "${linux_memory_output_cut}"' / 1024^2 + 1' | bc
    else
      exit 1
    fi
  fi
}

install_argo_cd() {
  runhub_yaml="$(helm template "${runhub_dir}"/charts/runhub)"
  argo_cd_yaml="$(echo "${runhub_yaml}" | yq --exit-status '
    select(.kind == "ApplicationSet" and .metadata.name == "runhub").spec.generators.[] |
    select(.list).list.elements.[] | select(.name == "argo-cd")')"
  argo_cd_version="$(echo "${argo_cd_yaml}" | yq --exit-status '.targetRevision')"
  argo_cd_values="$(echo "${argo_cd_yaml}" | yq --exit-status '.valuesObject')"

  echo 'Installing Argo CD and waiting until ready.'
  echo "${argo_cd_values}" | helm install --wait --create-namespace --namespace argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm argo-cd --version "${argo_cd_version}" \
    --values - > /dev/null
}

install_runhub() {
  echo 'Installing runhub.'
  helm install --create-namespace \
    --namespace runhub runhub-operator "${runhub_dir}"/charts/runhub-operator \
    --set repoURL=file:///runhub --set revision="$(git rev-parse --verify HEAD)" > /dev/null

  echo 'Waiting until runhub is ready.'
  kubectl config use-context k3d-dev-runhub-argocd-core > /dev/null
  argocd --core app wait runhub > /dev/null
  argocd --core app wait argo-cd > /dev/null
  kubectl config use-context k3d-dev-runhub > /dev/null
}

start() {
  previous_docker_context="$(docker context show)"
  previous_kube_context="$(kubectl config current-context 2> /dev/null || true)"
  total_number_cpus="$(getconf _NPROCESSORS_CONF)"
  total_gibibytes_memory="$(get_total_gibibytes_memory)"
  half_total_gibibytes_memory="$(echo "${total_gibibytes_memory}"' / 2' | bc)"

  echo 'Starting Colima Docker daemon.'
  colima start --profile dev-runhub \
    --cpu "${total_number_cpus}" --memory "${half_total_gibibytes_memory}" --disk 64
  echo 'Starting local dev Kubernetes cluster in Docker.'

  (
    RUNHUB_ABSOLUTE_DIR="$(cd "${runhub_dir}" && pwd)"
    export RUNHUB_ABSOLUTE_DIR

    k3d cluster create --config "${runhub_dir}"/dev-cluster.yaml
  )

  kubectl config set-context k3d-dev-runhub-argocd-core \
    --cluster k3d-dev-runhub --user admin@k3d-dev-runhub --namespace argocd > /dev/null
}

stop() {
  echo 'Stopping Colima Docker daemon and local dev Kubernetes cluster in Docker.'
  colima delete --force --profile dev-runhub

  docker context use "${previous_docker_context}" > /dev/null 2>&1 || true
  docker context rm --force colima-dev-runhub > /dev/null

  kubectl config use-context "${previous_kube_context}" > /dev/null 2>&1 \
    || kubectl config unset current-context > /dev/null
  kubectl config delete-context k3d-dev-runhub-argocd-core > /dev/null 2>&1 || true
  kubectl config delete-context k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-cluster k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-user admin@k3d-dev-runhub > /dev/null 2>&1 || true
}

main() {
  git -C "${runhub_dir}" config core.hooksPath git-hooks
  trap 'echo ; exit' INT
  trap 'stop' EXIT
  start
  install_argo_cd
  install_runhub
  echo 'Serving runhub at http://localhost:8080.'
  echo 'Press Ctrl+C to stop.'
  sleep 2147483647
}

main "$@"
