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
- `templates/secret.yaml`: chart-managed runtime secret fallback (including `DATABASE_URL` and `POSTGRES_PASSWORD`) for isolated/demo environments.
- `templates/serviceaccounts.yaml`: dedicated service accounts for the API and DB workloads. Identity names are defined in [security.md](../istio/security.md).
- `templates/NOTES.txt`: post-install access instructions.

## ⚙️ Main configurable values

- `nameOverride` and `fullnameOverride` for resource naming overrides when the default Helm naming convention is not desired.
- API image repo/tag/pull policy.
- API replica count, service type/port, container port, and resource requests/limits. The chart now defaults to `api.replicaCount: 2`; override it to `1` only for lightweight local clusters that do not need the extra replica.
- API health probes (`startup`, `readiness`, `liveness`) for startup and runtime stability.
- DB image repo/tag/pull policy.
- DB name/user/password and `db.existingSecret` for externally managed runtime credentials.
- DB service port, persistence toggle, storage size, optional storage class, and resource requests/limits.

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
- For shared environments, prefer `db.existingSecret` so secret values are externally owned instead of chart-generated.
- CI deploy flow enforces this shared-environment path by setting `db.existingSecret` to a pre-created secret name.
- For mesh-enabled environments, the target namespace baseline must already be compatible with Istio sidecar injection and leave enough quota headroom for workload containers plus sidecars.

```bash
minikube image load music-platform-api:1.7.0
helm upgrade --install music-platform helm/music-platform --namespace music-platform --create-namespace
kubectl get all -n music-platform
kubectl port-forward svc/music-platform-api 8000:8000 -n music-platform
```

Open:

- `http://127.0.0.1:8000/docs`

This example matches the current chart default in `values.yaml` (`api.image.tag: 1.7.0`). If your API image uses a different tag, update either:

- `helm/music-platform/values.yaml` (`api.image.tag`), or
- command line override:
  - `helm upgrade --install ... --set api.image.tag=<tag>`

If your local cluster is resource-constrained, you can also temporarily scale the API back down during install:

```bash
helm upgrade --install ... --set api.replicaCount=1
```

For migration ownership and rollout flow details, see [MIGRATIONS.md](../MIGRATIONS.md).
For namespace baseline and mesh-readiness prerequisites, see [Terraform integration flow](../terraform/flow-integration.md) and [Istio readiness](../istio/readiness.md).

---

## 🔗 Related documents

- [Kubernetes concept map](./k8s-concept-map.md)
- [Migration workflow](../MIGRATIONS.md)
- [Secrets ownership boundary](../SECRETS_OWNERSHIP.md)
- [Istio security](../istio/security.md)
- [Architecture decisions](../ARCHITECTURE.md)
