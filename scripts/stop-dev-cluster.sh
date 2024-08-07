#!/bin/sh

set -o errexit
set -o nounset

scripts_dir="$(dirname "$0")"
. "${scripts_dir}"/devbox-shellenv.sh

echo 'Stopping dev runhub cluster.'
k3d cluster stop dev-runhub || true
kubectl config unset current-context > /dev/null
kubectl config delete-context k3d-dev-runhub > /dev/null 2>&1 || true
kubectl config delete-cluster k3d-dev-runhub > /dev/null 2>&1 || true
kubectl config delete-user admin@k3d-dev-runhub > /dev/null 2>&1 || true
