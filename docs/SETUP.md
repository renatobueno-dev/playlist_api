# Setup Guide — Music Platform API

This document covers environment configuration and detailed setup steps for all execution modes.

> For API endpoints and schemas, see [API.md](./API.md). For architecture decisions, see [ARCHITECTURE.md](./ARCHITECTURE.md). For testing and CI, see [QUALITY.md](./QUALITY.md).

---

## 🔧 Environment Variables

### Local (without Docker)

`DATABASE_URL` is always required — `database.py` raises `RuntimeError` if it is missing. For a minimal local run without PostgreSQL, use a SQLite path.

To use PostgreSQL locally, copy `.env.example` and set values:

```bash
cp .env.example .env
```

| Variable            | Default in `.env.example`                                              | Description                                                                  |
| ------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `POSTGRES_DB`       | `music_platform`                                                       | Database name                                                                |
| `POSTGRES_USER`     | `postgres`                                                             | Database user                                                                |
| `POSTGRES_PASSWORD` | `postgres`                                                             | Database password                                                            |
| `POSTGRES_PORT`     | `5432`                                                                 | PostgreSQL port (host-side) — **Docker Compose only**                        |
| `API_PORT`          | `8000`                                                                 | API port exposed on host — **Docker Compose only**                           |
| `DATABASE_URL`      | `postgresql+psycopg://postgres:postgres@db:5432/music_platform`        | API runtime connection string used inside Docker Compose                     |
| `DATABASE_URL_HOST` | `postgresql+psycopg://postgres:postgres@localhost:5432/music_platform` | Host-side helper URL for local Alembic commands against the Compose database |

> `API_PORT` and `POSTGRES_PORT` are used exclusively by Docker Compose for host-side port mapping. They do not affect Kubernetes directly; cluster port configuration is controlled through Helm chart values such as `api.service.port` and `db.service.port`.

For local use with `uvicorn`, set `DATABASE_URL` directly if connecting to PostgreSQL:

```text
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/music_platform
```

If the database password contains reserved URL characters such as `@`, `#`, `?`, or `&`, URL-encode it in both `DATABASE_URL` and `DATABASE_URL_HOST`.

### Startup tuning variables

| Variable                   | Default | Description                        |
| -------------------------- | ------- | ---------------------------------- |
| `STARTUP_DB_MAX_RETRIES`   | `20`    | Max attempts to connect on startup |
| `STARTUP_DB_RETRY_SECONDS` | `2`     | Seconds between attempts           |

### Migration rule for all environments

Schema evolution is migration-owned.

- startup validates schema; it does not create tables
- run `alembic upgrade head` before expecting a healthy API startup
- current GitHub Actions deploy workflow does not run migrations automatically

For complete migration lifecycle rules, see [MIGRATIONS.md](./MIGRATIONS.md).

### Secret ownership rule for all environments

Secret handling is ownership-driven:

- local/compose: developer-managed values
- Kubernetes shared environments: prefer pre-created external Secret with `db.existingSecret`
- chart-managed secret generation: fallback for isolated/demo environments
- CI deploy credentials: GitHub repository secrets (`KUBE_CONFIG_DATA`)
- GitHub Actions does not inject runtime DB credentials; deploy expects runtime DB secret to exist in-cluster

Full boundary policy: [SECRETS_OWNERSHIP.md](./SECRETS_OWNERSHIP.md).

---

## 💻 Local Setup (without Docker)

**Prerequisites:** Python 3.12+, optionally PostgreSQL 16.

1. **Create and activate a virtual environment**

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate  # Windows: .\.venv\Scripts\activate
   ```

2. **Install dependencies**

   ```bash
   pip install -r requirements.txt -r requirements-dev.txt
   ```

3. **Set database URL**

   ```bash
   export DATABASE_URL=sqlite:///./music.db
   ```

4. **Apply migrations**

   ```bash
   ./.venv/bin/alembic upgrade head
   ```

5. **Start the server**

   ```bash
   uvicorn app.main:app --reload
   ```

6. **To use PostgreSQL locally** instead, set a PostgreSQL connection string before migrating:

   ```bash
   export DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/music_platform
   ./.venv/bin/alembic upgrade head
   uvicorn app.main:app --reload
   ```

> **Optional tuning:** `STARTUP_DB_MAX_RETRIES` and `STARTUP_DB_RETRY_SECONDS` control how long the app retries the database connection on startup. See the [startup tuning variables](#startup-tuning-variables) table above for defaults.

- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`
- Health: `http://127.0.0.1:8000/health`

---

## 🐳 Docker Setup

**Prerequisites:** Docker and Docker Compose installed, plus a local Python virtual environment with the project dependencies if you want to run the documented host-side Alembic command.

1. **Copy the environment file and load it into your shell**

   ```bash
   cp .env.example .env
   set -a
   source .env
   set +a
   ```

2. **Start database service**

   ```bash
   docker compose up -d db
   ```

3. **Run migrations from local virtualenv against Compose database**

   ```bash
   DATABASE_URL="${DATABASE_URL_HOST}" ./.venv/bin/alembic upgrade head
   ```

   This keeps the host-side Alembic command aligned with the same credentials as Docker Compose while still using `localhost` as the host-side endpoint.

4. **Start API service**

   ```bash
   docker compose up -d api
   ```

5. **Verify startup**

   ```bash
   # Tail logs until "Application startup complete" appears
   docker compose logs -f api
   # Check health endpoint
   curl "http://localhost:${API_PORT:-8000}/health"
   ```

6. **Tear down** (add `-v` to also remove the database volume)

   ```bash
   docker compose down
   docker compose down -v   # wipes PostgreSQL data
   ```

API available at: `http://localhost:<API_PORT>/` where `API_PORT` defaults to `8000`.

---

## ☸️ Kubernetes / Helm Setup

**Prerequisites:** `kubectl` configured, Minikube or cluster running, Helm 3.x, image built and accessible.

Supported cluster paths:

- **Local Helm-only path:** useful for quick local chart validation on a personal cluster.
- **Shared or Istio-enabled path:** use the full foundation flow in this order:
  1. apply Terraform namespace baseline first
  2. create or verify the external runtime DB secret
  3. deploy Helm workloads
  4. apply Alembic migrations to the cluster-reachable database
  5. apply rendered Istio traffic/security manifests

The steps below show the local Helm path first. For the full shared/mesh-enabled delivery order, see [Terraform integration flow](./terraform/flow-integration.md), [Migration workflow](./MIGRATIONS.md), and [Istio readiness](./istio/readiness.md).

1. **Load image into Minikube** (local cluster only)

   ```bash
   minikube image load music-platform-api:<tag>
   ```

   Replace `<tag>` with the value from `helm/music-platform/values.yaml` (`api.image.tag`) — currently `1.7.0`.

2. **Install the Helm chart**

   ```bash
   helm upgrade --install music-platform ./helm/music-platform \
     --namespace music-platform \
     --create-namespace
   ```

   The default chart path assembles and injects `DATABASE_URL` through `helm/music-platform/templates/secret.yaml`.
   For shared environments, prefer an externally managed secret and pass it explicitly:

   ```bash
   kubectl create secret generic music-platform-secret \
     --namespace music-platform \
     --from-literal=POSTGRES_PASSWORD='<strong-password>' \
     --from-literal=DATABASE_URL='postgresql+psycopg://postgres:<strong-password>@music-platform-db:5432/music_platform'

   helm upgrade --install music-platform ./helm/music-platform \
     --namespace music-platform \
     --create-namespace \
     --set db.existingSecret=music-platform-secret
   ```

   In CI deploy, this shared-environment path is enforced by default (`DB_EXISTING_SECRET_NAME`, default `music-platform-secret`).
   On a fresh database, apply migrations separately before expecting API readiness (`alembic upgrade head` with cluster-reachable DB endpoint).
   If the target namespace is shared or mesh-enabled, apply the Terraform namespace baseline before Helm so Pod Security labels and namespace guardrails are already in place for sidecar-injected workloads.

3. **Forward the API port**

   ```bash
   kubectl port-forward -n music-platform svc/music-platform-api 8000:8000
   ```

4. **Access**
   - Swagger: `http://localhost:8000/docs`
   - Health: `http://localhost:8000/health`

For Istio setup, verify readiness first: [`docs/istio/readiness.md`](./istio/readiness.md).

For Helm values reference, see [`docs/kubernetes/helm-guide.md`](./kubernetes/helm-guide.md).

---

## 🔗 Related documents

- [API reference](./API.md)
- [Architecture decisions](./ARCHITECTURE.md)
- [Secrets ownership boundary](./SECRETS_OWNERSHIP.md)
- [Migration workflow](./MIGRATIONS.md)
- [Quality guide](./QUALITY.md)
- [Development Log](./DEVELOPMENT_LOG.md)
- [Docker guide](./containers/docker-guide.md)
- [Helm guide](./kubernetes/helm-guide.md)
