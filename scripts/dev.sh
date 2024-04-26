#!/usr/bin/env sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
runhub_dir="${scripts_dir}"/..

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

  if k3d cluster get dev-runhub > /dev/null 2>&1; then
    k3d cluster start dev-runhub
    k3d kubeconfig merge --kubeconfig-merge-default dev-runhub > /dev/null
    until ctlptl get cluster k3d-dev-runhub --output yaml 2> /dev/null \
      | yq --exit-status '.k3d' > /dev/null 2>&1; do true; done
  fi

  k3d_version_output="$(k3d version --output json)"
  k3d_version="$(echo "${k3d_version_output}" | yq --exit-status '.k3d')"
  runhub_absolute_dir="$(cd "${runhub_dir}" && pwd)"
  export k3d_version runhub_absolute_dir
  dev_cluster_yaml="$(envsubst -no-unset -no-empty -i "${runhub_dir}"/dev-cluster.yaml)"
  echo "${dev_cluster_yaml}" | ctlptl apply --filename -
}

stop_dev_cluster() {
  echo 'Stopping dev runhub cluster.'
  kubectl drain k3d-dev-runhub-server-0 \
    --force --disable-eviction --delete-emptydir-data --ignore-daemonsets 2> /dev/null || true
  k3d cluster stop dev-runhub || true
  kubectl config delete-context k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-cluster k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config delete-user admin@k3d-dev-runhub > /dev/null 2>&1 || true
  kubectl config use-context "${previous_kube_context}" > /dev/null 2>&1 \
    || kubectl config unset current-context > /dev/null || true
}

stop_dev_docker() {
  echo 'Stopping dev runhub docker.'
  colima stop --profile dev-runhub || true
  docker context use "${previous_docker_context}" > /dev/null 2>&1 || true
}

get_current_commit() {
  git -C "${runhub_dir}" rev-parse --verify HEAD
}

has_new_commit() {
  [ "$(get_current_commit)" != "${current_commit}" ]
}

is_available() {
  kubectl get --namespace "$1" deployments,statefulsets --output yaml | yq --exit-status \
    '[.items[].status.availableReplicas // 0] | all_c(. >= 1)' > /dev/null 2>&1
}

is_healthy() {
  kubectl get --ignore-not-found applications.argoproj.io --namespace argocd "$1" --output yaml \
    | yq --exit-status '.status.health.status == "Healthy"' > /dev/null 2>&1
}

install_runhub() {
  echo 'Installing runhub.'
  helm upgrade --install --create-namespace --namespace runhub runhub-operator \
    "${runhub_dir}"/charts/runhub-operator \
    --set dev.repository='file:///runhub',dev.revision="${current_commit}" > /dev/null
}

install() {
  current_commit="$(get_current_commit)"

  if [ "${current_commit}" != "${previous_commit:-''}" ]; then
    echo 'Installing commit '"${current_commit}"'.'

    if ! "${is_argo_cd_ready:-false}"; then
      if "${scripts_dir}"/install-argo-cd.sh; then
        echo 'Waiting until Argo CD is ready.'
        until is_available argocd; do has_new_commit && return; sleep 1; done
        is_argo_cd_ready=true
      else
        echo 'Argo CD install failed, waiting for new commit.'
        until has_new_commit; do sleep 1; done
        return
      fi
    fi

    if install_runhub; then
      if ! "${is_runhub_ready:-false}"; then
        echo 'Waiting until runhub is ready.'
        until is_healthy runhub; do has_new_commit && return; sleep 1; done
        echo 'Waiting until Argo CD is ready.'
        until is_healthy argo-cd; do has_new_commit && return; sleep 1; done
        echo 'Waiting until Istio is ready.'
        until is_healthy istio-base; do has_new_commit && return; sleep 1; done
        until is_healthy istiod; do has_new_commit && return; sleep 1; done
        until is_healthy istio-ingressgateway; do has_new_commit && return; sleep 1; done
        until is_healthy runhub-routes; do has_new_commit && return; sleep 1; done
        until is_available istio-system; do has_new_commit && return; sleep 1; done
        is_runhub_ready=true
      fi
    else
      echo 'runhub install failed, waiting for new commit.'
      until has_new_commit; do sleep 1; done
      return
    fi

    echo 'Serving runhub at http://runhub.localhost:8080.'
    echo 'Waiting for new commit.'
    echo 'Press Ctrl+C to stop.'
    previous_commit="${current_commit}"
  fi
}

main() {
  previous_docker_context="$(docker context show)"
  previous_kube_context="$(kubectl config current-context 2> /dev/null || true)"

  (
    set -o monitor

    trap 'echo ; stop_dev_cluster ; stop_dev_docker ; exit 0' EXIT
    start_dev_docker
    start_dev_cluster

    while true; do install; sleep 1; done
  )
}

main "$@"
