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
   pip install -r requirements.txt
   ```

3. **Start the server with SQLite** (no PostgreSQL needed)
   ```bash
   export DATABASE_URL=sqlite:///./music.db
   uvicorn app.main:app --reload
   ```

4. **To use PostgreSQL locally** instead, set a PostgreSQL connection string:
   ```bash
   export DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/music_platform
   uvicorn app.main:app --reload
   ```

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

2. **Build and start**
   ```bash
   docker compose up --build
   ```

3. **Verify startup**
   ```bash
   # Tail logs until "Application startup complete" appears
   docker compose logs -f api
   # Check health endpoint
   curl http://localhost:8000/health
   ```

4. **Tear down** (add `-v` to also remove the database volume)
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
   minikube image load music-platform-api:latest
   ```

2. **Install the Helm chart**
   ```bash
   helm upgrade --install music-platform ./helm/music-platform \
     --namespace music-platform \
     --create-namespace
   ```

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
- [Quality guide](./QUALITY.md)
- [Development Log](./DEVELOPMENT_LOG.md)
- [Docker guide](./containers/docker-guide.md)
- [Helm guide](./kubernetes/helm-guide.md)
