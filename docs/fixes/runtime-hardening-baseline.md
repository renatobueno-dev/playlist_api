# Step 3 Fix: Runtime Hardening Baseline

> Closes visible runtime gaps: non-root container user, image healthcheck, Helm resource requests and limits, and explicit `DATABASE_URL` requirement.

---

## 🐛 Problem

Runtime posture still had visible hardening gaps:

- API container ran without explicit non-root user.
- Docker image had no healthcheck.
- Helm defaults had no resource requests/limits.
- Application silently fell back to SQLite when `DATABASE_URL` was not set.

## 🎯 Goal

Reduce weak-runtime signals while preserving existing architecture and deployment flow.

## 🔧 Implementation

### 1) Dockerfile hardening

File:

- `Dockerfile`

Changes:

- Added dedicated non-root runtime user:
  - `useradd --create-home --shell /usr/sbin/nologin app`
  - `USER app`
- Added image `HEALTHCHECK` against API health endpoint:
  - checks `http://127.0.0.1:8000/health` with timeout and retries.

Reason:

- Running as non-root and exposing health state are baseline container hardening expectations.

### 2) Explicit database configuration requirement

File:

- `app/database.py`

Change:

- Removed silent default fallback to `sqlite:///./music.db`.
- Application now raises a startup error if `DATABASE_URL` is not configured.

Reason:

- Prevents accidental drift between local, container, and cluster runtime behavior.
- Forces explicit environment configuration in all execution contexts.

### 3) Helm resource defaults

File:

- `helm/music-platform/values.yaml`

Changes:

- Added default API resources:
  - requests: `cpu 100m`, `memory 128Mi`
  - limits: `cpu 500m`, `memory 512Mi`
- Added default DB resources:
  - requests: `cpu 100m`, `memory 256Mi`
  - limits: `cpu 1`, `memory 1Gi`

Reason:

- Avoids unbounded runtime defaults and improves scheduler predictability.

## ✅ Validation

Commands:

```bash
docker build -t music-platform-api:runtime-step3 .
helm lint helm/music-platform
helm template music-platform helm/music-platform >/tmp/helm-step3.yaml
python3 -m compileall app
```

Checks:

- Docker build succeeds with non-root user and healthcheck in final image.
- Helm renders include API/DB resource requests and limits.
- Python modules compile successfully after DB configuration changes.

---

## 🔗 Related documents

- [Loose ends roadmap](./loose-ends-priority-roadmap.md)
- [Security defaults hardening](./security-defaults-hardening.md)
- [Helm guide](../kubernetes/helm-guide.md)

