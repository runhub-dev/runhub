#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

is_ready() {
  kubectl get --namespace "$1" pods --output yaml | yq --exit-status \
    '[.items[].status.containerStatuses[].ready // false] | all' > /dev/null 2>&1 && \
  kubectl get --namespace "$1" deployments,statefulsets --output yaml | yq --exit-status \
    '[.items[].status.availableReplicas // 0] | all_c(. >= 1)' > /dev/null 2>&1
}

get_revision() {
  git rev-parse --verify HEAD
}

install_argo_cd() {
  echo 'Installing Argo CD.'
  runhub_yaml="$(helm template "${runhub_dir}"/charts/runhub \
    --set repository=file:///runhub --set revision="$(get_revision)")"
  argo_cd_yaml="$(echo "${runhub_yaml}" | yq --exit-status '
    select(.kind == "ApplicationSet" and .metadata.name == "runhub").spec.generators.[] |
    select(.list).list.elements.[] | select(.name == "argo-cd")')"
  argo_cd_version="$(echo "${argo_cd_yaml}" | yq --exit-status '.targetRevision')"
  argo_cd_values="$(echo "${argo_cd_yaml}" | yq --exit-status '.valuesObject')"
  echo "${argo_cd_values}" | helm upgrade --install --create-namespace \
    --namespace argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm argo-cd --version "${argo_cd_version}" \
    --values - > /dev/null
  echo 'Waiting until Argo CD is ready.'
  until is_ready argocd; do sleep 1; done
}

install_runhub() {
  echo 'Installing runhub.'
  helm upgrade --install --create-namespace \
    --namespace runhub runhub-operator \
    "${runhub_dir}"/charts/runhub-operator \
    --set repository=file:///runhub --set revision="$1" > /dev/null
  echo 'Waiting until runhub is ready.'
  until kubectl get --namespace runhub applications.argoproj.io runhub-network \
    --output yaml 2> /dev/null | yq --exit-status \
    '.status.sync.status == "Synced" and .status.health.status == "Healthy"' \
    > /dev/null 2>&1; do sleep 1; done
  until is_ready istio-system; do sleep 1; done
}

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

start_dev_docker() {
  echo 'Starting dev runhub docker.'
  colima_template="$(colima template --print)"
  colima_template_dir="$(dirname "${colima_template}")"
  colima_lima_dir="${colima_template_dir}"/../_lima
  dev_docker="$(LIMA_HOME="${LIMA_HOME:-"${colima_lima_dir}"}" \
    limactl list colima-dev-runhub --format yaml 2> /dev/null)"
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
    --cpu "${total_number_cpus}" --memory "${half_total_gibibytes_memory}"
}

start_dev_cluster() {
  echo 'Starting dev runhub cluster.'
  k3d_version_output="$(k3d version --output json)"
  k3d_version="$(echo "${k3d_version_output}" | yq --exit-status '.k3d')"
  runub_absolute_dir="$(cd "${runhub_dir}" && pwd)"
  dev_cluster_yaml="$(helm template "${runhub_dir}"/charts/runhub-dev-cluster \
    --set k3dVersion="${k3d_version}" --set runhubAbsoluteDir="${runub_absolute_dir}")"

  if k3d cluster get dev-runhub > /dev/null 2>&1; then
    k3d cluster start dev-runhub
    k3d kubeconfig merge --kubeconfig-merge-default dev-runhub > /dev/null
    until ctlptl get cluster k3d-dev-runhub --output yaml 2> /dev/null \
      | yq --exit-status '.k3d' > /dev/null 2>&1; do true; done
  fi

  echo "${dev_cluster_yaml}" | ctlptl apply --filename -
}

stop_dev_cluster() {
  echo 'Stopping dev runhub cluster.'
  kubectl drain k3d-dev-runhub-server-0 \
    --force --disable-eviction --delete-emptydir-data --ignore-daemonsets > /dev/null 2>&1 || true
  kubectl config use-context "${previous_kube_context}" > /dev/null 2>&1 \
    || kubectl config unset current-context > /dev/null || true
  kubectl config delete-context k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-cluster k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-user admin@k3d-dev-runhub > /dev/null 2>&1 || true
  k3d cluster stop dev-runhub || true
}

stop_dev_docker() {
  echo 'Stopping dev runhub docker.'
  docker context use "${previous_docker_context}" > /dev/null 2>&1 || true
  docker context rm --force colima-dev-runhub > /dev/null || true
  colima stop --profile dev-runhub
}

main() {
  previous_docker_context="$(docker context show)"
  previous_kube_context="$(kubectl config current-context 2> /dev/null || true)"

  (
    set -o monitor

    trap 'echo ; stop_dev_cluster ; stop_dev_docker ; exit 0' EXIT
    start_dev_docker
    start_dev_cluster
    install_argo_cd

    while true; do
      current_revision="$(get_revision)"

      if [ "${current_revision}" != "${previous_revision:-''}" ]; then
        install_runhub "${current_revision}"
        echo 'Serving runhub at http://runhub.localhost:8080.'
        echo 'Press Ctrl+C to stop.'
        previous_revision="${current_revision}"
      fi

      sleep 1
    done
  )
}

main "$@"
