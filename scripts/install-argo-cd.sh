#!/usr/bin/env sh

set -o errexit
set -o nounset

ARGO_CD_CHART_VERSION='6.0.3'

echo 'Installing Argo CD.'

helm upgrade --install --wait --create-namespace --namespace argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm argo-cd --version "${ARGO_CD_CHART_VERSION}" \
  --values - > /dev/null \
<<END
configs:
  cm:
    admin.enabled: "false"
    users.anonymous.enabled: "true"
  params:
    server.insecure: "true"
  rbac:
    policy.default: role:admin
server:
  service:
    type: LoadBalancer
END

kubectl replace --filename - > /dev/null \
<<END
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  sourceNamespaces: []
  sourceRepos: []
  destinations: []
  namespaceResourceWhitelist: []
  clusterResourceWhitelist: []
END
