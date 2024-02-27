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
  if ! kubectl get applications.argoproj.io --namespace argocd argo-cd > /dev/null 2>&1; then
    echo 'Installing Argo CD and waiting until ready.'
    runhub_yaml="$(helm template "${runhub_dir}"/charts/runhub \
      --set repository=file:///runhub --set revision="$(git rev-parse --verify HEAD)")"
    argo_cd_yaml="$(echo "${runhub_yaml}" | yq --exit-status '
      select(.kind == "ApplicationSet" and .metadata.name == "runhub").spec.generators.[] |
      select(.list).list.elements.[] | select(.name == "argo-cd")')"
    argo_cd_version="$(echo "${argo_cd_yaml}" | yq --exit-status '.targetRevision')"
    argo_cd_values="$(echo "${argo_cd_yaml}" | yq --exit-status '.valuesObject')"
    echo "${argo_cd_values}" | helm upgrade --install --create-namespace --wait \
      --namespace argocd argo-cd \
      --repo https://argoproj.github.io/argo-helm argo-cd --version "${argo_cd_version}" \
      --values - > /dev/null
  fi
}

install_runhub() {
  echo 'Installing runhub and waiting until ready.'
  helm upgrade --install --create-namespace \
    --namespace runhub runhub-operator \
    "${runhub_dir}"/charts/runhub-operator \
    --set repository=file:///runhub --set revision="$(git rev-parse --verify HEAD)" > /dev/null

  while ! curl http://localhost:8080 > /dev/null 2>&1; do
    sleep 1
  done
}

start_dev_docker() {
  echo 'Starting dev runhub docker.'
  colima_template="$(colima template --print)"
  colima_template_dir="$(dirname "${colima_template}")"
  colima_lima_dir="${colima_template_dir}"/../_lima
  dev_docker="$(LIMA_HOME="${LIMA_HOME:-"${colima_lima_dir}"}" \
    limactl list --format yaml colima-dev-runhub 2> /dev/null)"
  colima_version_output="$(colima version)"
  colima_version_grep="$(echo "${colima_version_output}" | grep '^colima version ')"
  colima_version="$(echo "${colima_version_grep}" | cut -d ' ' -f 3)"
  
  if [ "${dev_docker}" ]; then
    dev_docker_colima_version="$(echo "${dev_docker}" \
      | yq --exit-status '.instance.config.env.RUNHUB_COLIMA_VERSION')"

    if [ "${dev_docker_colima_version}" != "${colima_version}" ]; then
      colima delete --force --profile dev-runhub > /dev/null 2>&1
    else
      colima stop --profile dev-runhub > /dev/null 2>&1
    fi
  fi

  total_number_cpus="$(getconf _NPROCESSORS_CONF)"
  total_gibibytes_memory="$(get_total_gibibytes_memory)"
  half_total_gibibytes_memory="$(echo "${total_gibibytes_memory}"' / 2' | bc)"
  colima start --profile dev-runhub --env RUNHUB_COLIMA_VERSION="${colima_version}" \
    --cpu "${total_number_cpus}" --memory "${half_total_gibibytes_memory}" --mount-type '9p'
}

start_dev_cluster() {
  echo 'Starting dev runhub cluster.'
  k3d_version_output="$(k3d version --output json)"
  k3d_version="$(echo "${k3d_version_output}" | yq --exit-status '.k3d')"
  runub_absolute_dir="$(cd "${runhub_dir}" && pwd)"
  dev_cluster_yaml="$(helm template "${runhub_dir}"/charts/dev-cluster \
    --set k3dVersion="${k3d_version}" --set runhubAbsoluteDir="${runub_absolute_dir}")"
  k3d kubeconfig merge --kubeconfig-merge-default dev-runhub > /dev/null 2>&1 || true
  echo "${dev_cluster_yaml}" | ctlptl apply --filename -
}

stop() {
  echo 'Stopping dev runhub docker and cluster.'
  colima stop --profile dev-runhub > /dev/null 2>&1

  docker context use "${previous_docker_context}" > /dev/null 2>&1 || true
  docker context rm --force colima-dev-runhub > /dev/null

  kubectl config use-context "${previous_kube_context}" > /dev/null 2>&1 \
    || kubectl config unset current-context > /dev/null
  kubectl config delete-context k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-cluster k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-user admin@k3d-dev-runhub > /dev/null 2>&1 || true
}

main() {
  git -C "${runhub_dir}" config core.hooksPath git-hooks
  trap 'echo ; exit' INT
  trap 'stop' EXIT
  previous_docker_context="$(docker context show)"
  previous_kube_context="$(kubectl config current-context 2> /dev/null || true)"
  start_dev_docker
  start_dev_cluster
  install_argo_cd
  install_runhub
  echo 'Serving runhub at http://localhost:8080.'
  echo 'Press Ctrl+C to stop.'
  sleep 2147483647
}

main "$@"
