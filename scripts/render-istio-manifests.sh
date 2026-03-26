#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-music-platform}"
RELEASE_NAME="${RELEASE_NAME:-music-platform}"
CHART_NAME="${CHART_NAME:-music-platform}"
ISTIO_HOST="${ISTIO_HOST:-playcatch.local}"
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-cluster.local}"

if [[ "${RELEASE_NAME}" == *"${CHART_NAME}"* ]]; then
  HELM_FULLNAME="${RELEASE_NAME}"
else
  HELM_FULLNAME="${RELEASE_NAME}-${CHART_NAME}"
fi

API_SERVICE_NAME="${API_SERVICE_NAME:-${HELM_FULLNAME}-api}"
API_SERVICE_ACCOUNT="${API_SERVICE_ACCOUNT:-${HELM_FULLNAME}-api-sa}"
API_SERVICE_HOST="${API_SERVICE_HOST:-${API_SERVICE_NAME}.${NAMESPACE}.svc.cluster.local}"

render_template() {
  local template_file="$1"

  sed \
    -e "s|__NAMESPACE__|${NAMESPACE}|g" \
    -e "s|__ISTIO_HOST__|${ISTIO_HOST}|g" \
    -e "s|__API_SERVICE_HOST__|${API_SERVICE_HOST}|g" \
    -e "s|__CLUSTER_DOMAIN__|${CLUSTER_DOMAIN}|g" \
    -e "s|__API_SERVICE_ACCOUNT__|${API_SERVICE_ACCOUNT}|g" \
    "${template_file}"
}

render_template "k8s/istio/traffic-management.yaml"
echo "---"
render_template "k8s/istio/security-policies.yaml"
