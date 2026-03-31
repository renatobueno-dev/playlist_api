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

| Variable            | Default in `.env.example` | Description                            |
|---------------------|---------------------------|----------------------------------------|
| `POSTGRES_DB`       | `music_platform`          | Database name                          |
| `POSTGRES_USER`     | `postgres`                | Database user                          |
| `POSTGRES_PASSWORD` | `postgres`                | Database password                      |
| `POSTGRES_PORT`     | `5432`                    | PostgreSQL port (host-side) — **Docker Compose only** |
| `API_PORT`          | `8000`                    | API port exposed on host — **Docker Compose only** |

> `API_PORT` and `POSTGRES_PORT` are used exclusively by Docker Compose for host-side port mapping. They have no effect in Kubernetes — port configuration there is hardcoded in Helm `values.yaml` (`api.service.port` and `db.service.port`).

`DATABASE_URL` is assembled by Docker Compose from the individual variables:
```
postgresql+psycopg://<POSTGRES_USER>:<POSTGRES_PASSWORD>@db:5432/<POSTGRES_DB>
```

For local use with `uvicorn`, set `DATABASE_URL` directly if connecting to PostgreSQL:
```
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/music_platform
```

### Startup tuning variables

| Variable                   | Default | Description                         |
|----------------------------|---------|-------------------------------------|
| `STARTUP_DB_MAX_RETRIES`   | `20`    | Max attempts to connect on startup  |
| `STARTUP_DB_RETRY_SECONDS` | `2`     | Seconds between attempts            |

### Migration rule for all environments

Schema evolution is migration-owned.

- startup validates schema; it does not create tables
- run `alembic upgrade head` before expecting a healthy API startup
- current GitHub Actions deploy workflow does not run migrations automatically

For complete migration lifecycle rules, see [MIGRATIONS.md](./MIGRATIONS.md).

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

**Prerequisites:** Docker and Docker Compose installed.

1. **Copy the environment file**
   ```bash
   cp .env.example .env
   ```

2. **Start database service**
   ```bash
   docker compose up -d db
   ```

3. **Run migrations from local virtualenv against Compose database**
   ```bash
   export DATABASE_URL=postgresql+psycopg://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-postgres}@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-music_platform}
   ./.venv/bin/alembic upgrade head
   ```

4. **Start API service**
   ```bash
   docker compose up -d api
   ```

5. **Verify startup**
   ```bash
   # Tail logs until "Application startup complete" appears
   docker compose logs -f api
   # Check health endpoint
   curl http://localhost:8000/health
   ```

6. **Tear down** (add `-v` to also remove the database volume)
   ```bash
   docker compose down
   docker compose down -v   # wipes PostgreSQL data
   ```

API available at: `http://localhost:8000/`

---

## ☸️ Kubernetes / Helm Setup

**Prerequisites:** `kubectl` configured, Minikube or cluster running, Helm 3.x, image built and accessible.

1. **Load image into Minikube** (local cluster only)
   ```bash
   minikube image load music-platform-api:1.6.1
   ```

2. **Install the Helm chart**
   ```bash
   helm upgrade --install music-platform ./helm/music-platform \
     --namespace music-platform \
     --create-namespace
   ```

   The default chart path assembles and injects `DATABASE_URL` through `helm/music-platform/templates/secret.yaml`, so you do not need to set it manually for Kubernetes installs unless you are overriding the chart's secret handling.
   On a fresh database, apply migrations separately before expecting API readiness (`alembic upgrade head` with cluster-reachable DB endpoint).

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
- [Migration workflow](./MIGRATIONS.md)
- [Quality guide](./QUALITY.md)
- [Development Log](./DEVELOPMENT_LOG.md)
- [Docker guide](./containers/docker-guide.md)
- [Helm guide](./kubernetes/helm-guide.md)
