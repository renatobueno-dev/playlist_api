# Step 2 Fix: Security Defaults Hardening

> Replaces weak Helm defaults (image tag, plaintext DB password, direct secret injection) with intentional, non-demo-grade values and an `existingSecret` fallback strategy.

---

## 🐛 Problem

Helm defaults exposed weak security posture:

- API image default tag used `latest`.
- `db.password` default was plaintext (`postgres`) in `values.yaml`.
- Secret template used chart values directly, encouraging demo-style secret handling.

## 🎯 Goal

Make chart defaults safer and more intentional without breaking deployment flow.

## 🔧 Implementation

### 1) Safer API image default tag

File:

- `helm/music-platform/values.yaml`

Change:

- At Step 2 implementation time, `api.image.tag` changed from `latest` to `0.1.0` to remove floating defaults.

Reason:

- Avoids floating default behavior.

Current baseline:

- The chart now tracks release-tag values in `helm/music-platform/values.yaml` (currently `1.6.1`), not `0.1.0`.

### 2) Removed plaintext DB password default

File:

- `helm/music-platform/values.yaml`

Changes:

- `db.password` changed from `postgres` to empty string.
- Added `db.existingSecret` (default empty) to support externally managed credentials.

Reason:

- Removes insecure default credential from chart values.
- Enables secret ownership outside the chart when required.

### 3) Hardened secret template behavior

Files:

- `helm/music-platform/templates/_helpers.tpl`
- `helm/music-platform/templates/secret.yaml`

Changes:

- Secret name helper now uses `db.existingSecret` when provided.
- Secret template is skipped when `db.existingSecret` is set.
- For chart-managed secrets:
  - Reuses existing in-cluster `POSTGRES_PASSWORD` when available (`lookup`), reducing rotation risk.
  - Uses `db.password` only when explicitly provided.
  - Otherwise generates a random password (`randAlphaNum 40`) instead of defaulting to demo credentials.

Reason:

- Removes direct dependency on insecure default values.
- Improves credential handling while preserving install/upgrade usability.

## ✅ Validation

Commands:

```bash
helm lint helm/music-platform
helm template music-platform helm/music-platform >/tmp/helm-step2.yaml
helm template music-platform helm/music-platform --set db.existingSecret=my-db-secret >/tmp/helm-step2-existing-secret.yaml
```

Checks:

- Chart lints successfully.
- Default render contains Secret with non-empty password and `DATABASE_URL`.
- Render with `db.existingSecret` does not create chart-managed Secret and references `my-db-secret` in API/DB manifests.

---

## 🔗 Related documents

- [Loose ends roadmap](./loose-ends-priority-roadmap.md)
- [Helm guide](../kubernetes/helm-guide.md)
- [Runtime hardening](./runtime-hardening-baseline.md)
