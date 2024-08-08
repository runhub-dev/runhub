#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
devbox_shellenv="$("${scripts_dir}"/devbox-shellenv.sh)"
eval "${devbox_shellenv}"

k3s_version='v1.30.2-k3s2'

get_k3d_version() (
  k3d_version_output="$(k3d version --output json)"
  echo "${k3d_version_output}" | yq --exit-status '.k3d'
)

get_dev_cluster_config() (
  k3d_version="$(get_k3d_version)"
cat <<END  
apiVersion: ctlptl.dev/v1alpha1
kind: Cluster
name: k3d-dev-runhub
product: k3d
k3d:
  v1alpha5Simple:
    metadata:
      name: k3d-${k3d_version}
    image: rancher/k3s:${k3s_version}
    options:
      k3s:
        extraArgs:
          - arg: --disable=traefik
            nodeFilters:
              - server:0
END
)

main() (
  "${scripts_dir}"/start-dev-docker.sh
  echo 'Starting dev runhub cluster.'
  dev_cluster="$(k3d cluster get dev-runhub --output yaml 2> /dev/null || true)"

  if [ "${dev_cluster}" ]; then
    k3d kubeconfig merge --kubeconfig-merge-default dev-runhub > /dev/null
    dev_cluster_servers_running="$(echo "${dev_cluster}" | yq --exit-status '.[].serversRunning')"

    if [ "${dev_cluster_servers_running}" = 0 ]; then
      k3d cluster start dev-runhub
    fi
  fi

  dev_cluster_config="$(get_dev_cluster_config)"
  echo "${dev_cluster_config}" | ctlptl apply --filename -
)

main "$@"
