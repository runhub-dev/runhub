#!/usr/bin/env sh

set -o errexit
set -o nounset
set -o xtrace

configurations="$(kubectl get configurations.serving.knative.dev --namespace "$1" --output \
  jsonpath='{range .items[*]}{.metadata.name}{"_"}{.status.latestReadyRevisionName}{" "}{end}')"

for configuration in ${configurations}; do
name="$(echo "${configuration}" | cut -d '_' -f 1)"
revision="$(echo "${configuration}" | cut -d '_' -f 2)"
routes="${routes:-}""$(cat <<END

---
apiVersion: serving.knative.dev/v1
kind: Route
metadata:
  name: "${name}"
  namespace: "$1"
spec:
  traffic:
    - revisionName: "${revision}"
      percent: 100
END
)"
done

echo "${routes}" \
  | kubectl apply --server-side --force-conflicts --field-manager routes-hook --filename -
