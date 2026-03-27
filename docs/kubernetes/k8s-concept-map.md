# Kubernetes Concept Map

> Translates every Docker/Compose concept to its Kubernetes equivalent before writing any YAML. Reference this before reading Helm templates or cluster manifests.

---

Design translation step: maps every Docker/Compose concept to its Kubernetes equivalent before writing any YAML.

## 🎯 Goal of the translation

Move from:
- "Docker/Compose runs my stack locally"

To:
- "Kubernetes resources describe and operate my stack consistently"

## 📦 Current container model (input)

From `Dockerfile` + `docker-compose.yml`:
- API container runs `uvicorn app.main:app --host 0.0.0.0 --port 8000`
- API service exposes host `8000 -> container 8000`
- PostgreSQL service runs as dependency
- API receives DB connection via `DATABASE_URL`
- DB has persistent storage via named Docker volume
- Compose `depends_on` + DB healthcheck control startup order

## 🔄 Compose -> Kubernetes mapping

| Compose concept | Kubernetes concept | Notes |
| --- | --- | --- |
| `api` service container | `Deployment` for API Pods | Runtime unit for stateless app replicas. |
| `db` service container | `StatefulSet` (preferred) or `Deployment` | DB is stateful; `StatefulSet` is safer for identity/storage semantics. |
| `ports: 8000:8000` for API | `Service` (ClusterIP) + external access option (`NodePort` / Ingress / port-forward) | In Minikube, `NodePort` or `kubectl port-forward` is simplest. |
| Compose service-to-service DNS (`db`) | Kubernetes DNS (`db.<namespace>.svc`) via `Service` | App should connect to DB service name, not pod IP. |
| Environment variables in Compose | `ConfigMap` + `Secret` + pod `env` | Non-sensitive values in `ConfigMap`; credentials in `Secret`. |
| Compose startup dependency (`depends_on`) | Readiness model + optional init wait logic | Kubernetes does not use `depends_on`; probes and retries are the control mechanism. |
| DB volume (`postgres_data`) | `PersistentVolumeClaim` (+ StorageClass) | Keeps DB data across pod restarts/re-schedules. |
| Container restart policy | Controller reconciliation (Deployment/StatefulSet) | Controller ensures desired state continuously. |

## ⚙️ Runtime unit decisions for this project

### API runtime unit

- Resource type: `Deployment`
- Why: API is stateless and horizontally scalable.
- Exposure:
  - Internal: `Service` on port `8000`
  - External in Minikube: `NodePort` or `kubectl port-forward`

### Database runtime unit

- Resource type: `StatefulSet` (recommended for Phase 3)
- Why: Stable identity and attached persistent storage are required for DB reliability.
- Storage:
  - One PVC for PostgreSQL data path
- Exposure:
  - Internal `Service` only (no external exposure required for app runtime)

## 🗂️ Configuration translation

### ConfigMap candidates

- `POSTGRES_DB`
- `POSTGRES_USER` (can also be secret depending policy)
- API non-sensitive runtime variables (for example host/port flags if needed)

### Secret candidates

- `POSTGRES_PASSWORD`
- Optional: full `DATABASE_URL` if treated as sensitive

### API DB connection strategy

Preferred approach:
- Build `DATABASE_URL` from env parts in pod env, or pass full URL from `Secret`.
- Ensure host is Kubernetes DB service name, not `localhost`.

## 🏥 Health and dependency translation

Compose uses `depends_on`; Kubernetes uses probes and controller retries.

Recommended for Phase 3 manifests:
- API:
  - `readinessProbe` on `/health`
  - `livenessProbe` on `/health`
- DB:
  - readiness using PostgreSQL probe command
- Optional:
  - API init container or startup retry logic if strict startup gating is desired

## 🌐 Service exposure translation

For local Minikube validation:
- Option 1: `kubectl port-forward service/api 8000:8000`
- Option 2: API `Service` as `NodePort`

For production-style setups (later):
- `Ingress` + controller for HTTP routing

## 🧠 Helm translation mindset

Helm should parameterize environment differences, not duplicate logic.

Likely chart value groups:
- `image.repository`, `image.tag`, `image.pullPolicy`
- `api.replicaCount`, `api.resources`, `api.service.type`, `api.service.port`
- `database.enabled`, `database.image`, `database.persistence.size`
- `env` non-sensitive map
- `secrets` references or generated secrets

Template families to expect:
- `deployment.yaml` (API)
- `service.yaml` (API and DB internal service)
- `statefulset.yaml` (DB)
- `configmap.yaml`
- `secret.yaml`
- `pvc.yaml`
- optional `ingress.yaml`

## ✅ Phase 2 completion criteria

This conceptual translation is complete when:
- Every Compose responsibility has a Kubernetes equivalent.
- API runtime, service exposure, configuration, and persistence strategy are explicitly defined.
- Helm parameterization boundaries are clear before writing YAML templates.

---

## 🔗 Related documents

- [Helm guide](./helm-guide.md)
- [Docker guide](../containers/docker-guide.md)
- [Architecture decisions](../ARCHITECTURE.md)
