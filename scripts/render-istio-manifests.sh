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

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[|&\\]/\\&/g'
}

render_template() {
  local template_file="$1"
  local escaped_namespace
  local escaped_istio_host
  local escaped_api_service_host
  local escaped_cluster_domain
  local escaped_api_service_account

  escaped_namespace="$(escape_sed_replacement "${NAMESPACE}")"
  escaped_istio_host="$(escape_sed_replacement "${ISTIO_HOST}")"
  escaped_api_service_host="$(escape_sed_replacement "${API_SERVICE_HOST}")"
  escaped_cluster_domain="$(escape_sed_replacement "${CLUSTER_DOMAIN}")"
  escaped_api_service_account="$(escape_sed_replacement "${API_SERVICE_ACCOUNT}")"

  sed \
    -e "s|__NAMESPACE__|${escaped_namespace}|g" \
    -e "s|__ISTIO_HOST__|${escaped_istio_host}|g" \
    -e "s|__API_SERVICE_HOST__|${escaped_api_service_host}|g" \
    -e "s|__CLUSTER_DOMAIN__|${escaped_cluster_domain}|g" \
    -e "s|__API_SERVICE_ACCOUNT__|${escaped_api_service_account}|g" \
    "${template_file}"
}

render_template "k8s/istio/traffic-management.yaml"
echo "---"
render_template "k8s/istio/security-policies.yaml"
