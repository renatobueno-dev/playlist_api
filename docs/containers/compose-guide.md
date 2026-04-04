# Docker Compose Workflow

> Steps D and E of the containerisation process: adding the database service and validating the full multi-service stack. Assumes the API image is already validated — see [docker-guide.md](./docker-guide.md) first.

---

## 🔧 Step D - Add Docker Compose (API + DB)

Goal:

- Run API and database as separate services managed together.

Compose must include:

- `api` service (FastAPI container).
- `db` service (PostgreSQL container) — the image is SHA-pinned (`postgres:16-alpine@sha256:20edbde7...`) for the same supply-chain reason as the API base image: tag pinning alone is not immutable.
- explicit `DATABASE_URL` pointing from `api` to `db` service name.
- Service dependency/health strategy (`depends_on` + DB healthcheck).

This workflow still uses the host Python environment for the Alembic step, so keep `.venv` and the project dependencies available locally before running it.

Commands:

```bash
cp .env.example .env
set -a
source .env
set +a
docker compose up -d --build db
DATABASE_URL="${DATABASE_URL_HOST}" ./.venv/bin/alembic upgrade head
docker compose up -d api
docker compose ps
```

Notes:

- `.env` keeps two connection strings on purpose:
  - `DATABASE_URL` for the API container, which must reach PostgreSQL through the Compose service host `db`
  - `DATABASE_URL_HOST` for host-side Alembic commands, which must reach PostgreSQL through `localhost`
- If the password contains reserved URL characters, URL-encode it in both values instead of relying on Compose to rebuild the URL from raw password parts.

Validation:

```bash
curl "http://127.0.0.1:${API_PORT:-8000}/health"
curl -X POST "http://127.0.0.1:${API_PORT:-8000}/songs/" \
  -H "Content-Type: application/json" \
  -d '{"title":"Compose Song","artist":"Compose Tester"}'
curl "http://127.0.0.1:${API_PORT:-8000}/songs/"
docker compose exec -T db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT COUNT(*) FROM songs;"
```

Checkpoint:

- Both services are running.
- API can read/write data with DB.
- Host-to-API mapping (`localhost:${API_PORT:-8000} -> api:8000`) works.
- Schema has been applied through Alembic before API startup.

## ✅ Step E - Validate logs

Goal:

- Confirm there are no hidden startup, import, or DB connection errors.

Commands:

```bash
docker compose logs --tail=200 api
docker compose logs --tail=200 db
```

Expected API signals:

- `Started server process`
- `Waiting for application startup`
- `Application startup complete`
- `Uvicorn running on http://0.0.0.0:8000`

Expected DB signals:

- `database system is ready to accept connections`
- `listening on ... port 5432`

Red flags:

- `Traceback`
- `ModuleNotFoundError`
- `ImportError`
- `OperationalError`
- `connection refused`
- `could not connect`

Checkpoint:

- Startup and readiness logs are clean.
- No unresolved runtime or connectivity errors.

## 🧹 Cleanup commands

```bash
docker compose down
docker compose down -v
```

Use `-v` to remove persisted DB volume and restart from a clean state.

---

## 🔗 Related documents

- [Docker image workflow](./docker-guide.md)
- [Kubernetes concept map](../kubernetes/k8s-concept-map.md)
- [Setup guide](../SETUP.md)
