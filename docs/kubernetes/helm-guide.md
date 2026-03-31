# Helm Chart Guide

> Reference guide for the `helm/music-platform` chart. Covers chart structure, configurable values, probe tuning, and local validation commands.

---

Organises Kubernetes deployment into a reusable Helm chart.

## 📂 Chart location

`helm/music-platform`

## 📁 Chart structure

```text
helm/music-platform/
├── .helmignore
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── NOTES.txt
    ├── api-deployment.yaml
    ├── api-service.yaml
    ├── configmap.yaml
    ├── db-service.yaml
    ├── db-statefulset.yaml
    ├── secret.yaml
    └── serviceaccounts.yaml
```

## 📖 What each part does

- `Chart.yaml`: chart metadata and versioning.
- `values.yaml`: central place for configurable parameters.
- `templates/_helpers.tpl`: shared naming and label helpers.
- `templates/api-*.yaml`: API runtime and service exposure.
- `templates/db-*.yaml`: PostgreSQL runtime and service identity.
- `templates/configmap.yaml`: non-sensitive DB configuration.
- `templates/secret.yaml`: sensitive values, including `DATABASE_URL`.
- `templates/serviceaccounts.yaml`: dedicated service accounts for the API and DB workloads. Identity names are defined in [security.md](../istio/security.md).
- `templates/NOTES.txt`: post-install access instructions.

## ⚙️ Main configurable values

- API image repo/tag/pull policy.
- API replica count and service type/port.
- API health probes (`startup`, `readiness`, `liveness`) for startup and runtime stability.
- DB image repo/tag/pull policy.
- DB name/user/password.
- DB persistence toggle, storage size, and optional storage class.

## ⏱️ Probe tuning for smoother startup

The API Deployment includes all three HTTP probes at `/health`:

- `startupProbe`: allows extra warm-up time before liveness/readiness are enforced.
- `readinessProbe`: marks the pod ready to receive traffic.
- `livenessProbe`: restarts a stuck process.

Default startup values in `values.yaml`:

```yaml
api:
  probes:
    startup:
      initialDelaySeconds: 5
      periodSeconds: 2
      timeoutSeconds: 2
      failureThreshold: 30
```

This gives the container up to ~65 seconds to finish startup before Kubernetes treats it as failed.

## ✅ Validate chart locally

Install Helm if needed:

```bash
brew install helm
```

Lint and render:

```bash
helm lint helm/music-platform
helm template music-platform helm/music-platform
```

## ☁️ Install to Minikube

Schema prerequisite:

- This chart does not execute Alembic migrations automatically.
- On a fresh database, schema must be migrated separately before API pods can become reliably healthy.

```bash
minikube image load music-platform-api:1.6.1
helm upgrade --install music-platform helm/music-platform --namespace music-platform --create-namespace
kubectl get all -n music-platform
kubectl port-forward svc/music-platform-api 8000:8000 -n music-platform
```

Open:
- `http://127.0.0.1:8000/docs`

This example matches the current chart default in `values.yaml` (`api.image.tag: 1.6.1`). If your API image uses a different tag, update either:
- `helm/music-platform/values.yaml` (`api.image.tag`), or
- command line override:
  - `helm upgrade --install ... --set api.image.tag=<tag>`

For migration ownership and rollout flow details, see [MIGRATIONS.md](../MIGRATIONS.md).

---

## 🔗 Related documents

- [Kubernetes concept map](./k8s-concept-map.md)
- [Migration workflow](../MIGRATIONS.md)
- [Istio security](../istio/security.md)
- [Architecture decisions](../ARCHITECTURE.md)
