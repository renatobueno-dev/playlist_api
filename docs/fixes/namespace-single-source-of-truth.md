# Step 1 Fix: Namespace Single Source of Truth

> Defines a single runtime namespace source for Terraform, GitHub Actions, and Istio manifests. Eliminates drift risk from hardcoded namespace values.

---

## 🐛 Problem

Namespace ownership was split across three independent places:

- Terraform variable (`namespace_name`)
- GitHub Actions workflow env (`NAMESPACE`)
- hardcoded `music-platform` values inside Istio manifests

This creates drift risk and makes namespace changes fragile.

## 🎯 Goal

Use one runtime namespace source in deployment flow and ensure Istio resources follow it consistently.

## 🔧 Implementation

### 1) Templated Istio manifests

Files:

- `k8s/istio/traffic-management.yaml`
- `k8s/istio/security-policies.yaml`

Changes:

- Replaced hardcoded namespace and identity values with placeholders:
  - `__NAMESPACE__`
  - `__ISTIO_HOST__`
  - `__ISTIO_TLS_SECRET__`
  - `__API_SERVICE_HOST__`
  - `__CLUSTER_DOMAIN__`
  - `__API_SERVICE_ACCOUNT__`

Result:

- Istio manifests no longer hardcode `music-platform` and can be rendered per environment.

### 2) Added render script for Istio manifests

File:

- `scripts/render-istio-manifests.sh`

Behavior:

- Reads `NAMESPACE` and `RELEASE_NAME` from environment.
- Derives Helm-style API service name/account defaults.
- Renders both Istio files with resolved runtime values.

Result:

- Istio manifest namespace and identity values are generated from the same deploy-time inputs used by workflow/Terraform.

### 3) Workflow integration

File:

- `.github/workflows/deploy.yml`

Changes:

- Validation job now renders Istio manifests:
  - `./scripts/render-istio-manifests.sh >/tmp/istio-rendered.yaml`
- Deploy job now applies rendered manifests with explicit namespace:
  - `./scripts/render-istio-manifests.sh | kubectl apply -n "${NAMESPACE}" -f -`

Result:

- Workflow and Istio apply path share the same namespace source (`NAMESPACE`).
- Namespace drift between workflow and raw Istio files is removed.

## ✅ Validation

Run locally:

```bash
./scripts/render-istio-manifests.sh >/tmp/istio-rendered.yaml
rg "__NAMESPACE__|__ISTIO_HOST__|__ISTIO_TLS_SECRET__|__API_SERVICE_HOST__|__CLUSTER_DOMAIN__|__API_SERVICE_ACCOUNT__" /tmp/istio-rendered.yaml
```

Expected:

- Render command succeeds.
- Placeholder search returns no matches.

Optional custom namespace check:

```bash
NAMESPACE=music-platform-dev RELEASE_NAME=music-platform ./scripts/render-istio-manifests.sh >/tmp/istio-dev.yaml
rg "music-platform-dev" /tmp/istio-dev.yaml
```

Expected:

- Rendered resources and authorization principals use `music-platform-dev`.

---

## 🔗 Related documents

- [Loose ends roadmap](./loose-ends-priority-roadmap.md)
- [Istio traffic management](../istio/traffic.md)
- [GitHub Actions guide](../cicd/github-actions.md)
