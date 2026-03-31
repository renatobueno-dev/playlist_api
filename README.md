# Music Platform API

![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.135.1-009688?logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Helm-326CE5?logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![CI](https://github.com/renatobueno-dev/music-platform/actions/workflows/deploy.yml/badge.svg)
![Istio](https://img.shields.io/badge/Istio-service_mesh-466BB0?logo=istio&logoColor=white)

## 📚 Purpose

Educational project focused on consolidating real backend and deployment practices with FastAPI. Domain: `Song` + `Playlist` with many-to-many through `playlist_songs`, built across 4 progressive infrastructure stages: local → Docker/Compose → Kubernetes/Helm → Istio/Terraform/CI.

- REST API with a simple but representative domain (songs and playlists)
- Kubernetes workload management with Helm and Istio service mesh
- Infrastructure as code with Terraform
- Automated CI/CD pipeline with GitHub Actions

> 💡 **Want to understand the development process?** See [Development Log](docs/DEVELOPMENT_LOG.md) for decisions, corrections, and reasoning recorded during each stage.

## ⚠️ Security note

This repository is for study. Before using in production:
- Use strong, real secrets in environment variables — never commit `.env`
- Set `DATABASE_URL` and all credentials via injected secrets, not hardcoded defaults
- Restrict CORS origins and rotate all credentials before exposure

---

## Project structure

```text
.
├── .github/workflows/deploy.yml   # CI/CD pipeline
├── CHANGELOG.md
├── alembic.ini
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── requirements.txt
├── requirements-dev.txt
├── app/                           # FastAPI application
│   ├── main.py
│   ├── database.py
│   ├── models/      (song, playlist, playlist_song, base)
│   ├── schemas/     (song, playlist)
│   ├── routes/      (health, songs, playlists)
│   └── services/    (song_service, playlist_service)
├── migrations/                    # Alembic migration home
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
├── helm/music-platform/           # Helm chart
│   ├── Chart.yaml / values.yaml
│   └── templates/   (deployment, service, statefulset, configmap, secret, serviceaccounts)
├── k8s/istio/                     # Istio manifests
│   ├── traffic-management.yaml
│   └── security-policies.yaml
├── scripts/                       # Deployment helpers
│   └── render-istio-manifests.sh
├── terraform/                     # Environment foundation
│   ├── main.tf / variables.tf / outputs.tf / versions.tf / backend.tf
├── docs/                          # Reference documentation (by topic)
│   ├── README.md                  # Navigation index
│   ├── domain/      (domain-scope, crud-endpoint-plan)
│   ├── containers/  (docker-guide, compose-guide)
│   ├── kubernetes/  (k8s-concept-map, helm-guide)
│   ├── istio/       (readiness, traffic, security)
│   ├── cicd/        (github-actions)
│   └── terraform/   (scope-and-boundary, flow-integration)
```

**Request layer flow:** `routes` → `schemas` → `services` → `models` → `database`

---

## How to run locally

1. Create and activate a virtual environment:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate  # Windows: .\.venv\Scripts\activate
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt -r requirements-dev.txt
   ```
3. Set database URL and apply migrations:
   ```bash
   export DATABASE_URL=sqlite:///./music.db
   ./.venv/bin/alembic upgrade head
   ```
4. Start the server:
   ```bash
   uvicorn app.main:app --reload
   ```
   To use PostgreSQL instead, set `DATABASE_URL` to a connection string (see [SETUP.md](docs/SETUP.md)).
   For migration lifecycle rules (when to create revisions, baseline stamp flow, and deployment expectations), see [MIGRATIONS.md](docs/MIGRATIONS.md).

- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

## How to run with Docker

```bash
cp .env.example .env
docker compose up -d db
export DATABASE_URL=postgresql+psycopg://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-postgres}@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-music_platform}
./.venv/bin/alembic upgrade head
docker compose up -d api
```

API: `http://localhost:8000/`

---

## API endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/` | API status message |
| `GET` | `/health` | Service healthcheck |
| `GET/POST` | `/songs/` | List / create songs |
| `GET/PATCH/DELETE` | `/songs/{song_id}` | Get / update / delete song |
| `GET/POST` | `/playlists/` | List / create playlists |
| `GET/PATCH/DELETE` | `/playlists/{playlist_id}` | Get / update / delete playlist |
| `POST` | `/playlists/{playlist_id}/songs/{song_id}` | Link song to playlist |
| `DELETE` | `/playlists/{playlist_id}/songs/{song_id}` | Unlink song from playlist |

Playlist `PATCH` accepts optional `song_ids` — if provided, links are replaced; if omitted, unchanged.
Non-existent IDs return `404`.

---

## Documentation

Full reference in [`docs/`](./docs/README.md):

| Topic | Files |
| --- | --- |
| Project-wide | [CHANGELOG.md](./CHANGELOG.md) · [ARCHITECTURE.md](./docs/ARCHITECTURE.md) · [INFRA_DECISIONS.md](./docs/INFRA_DECISIONS.md) · [SETUP.md](./docs/SETUP.md) · [MIGRATIONS.md](./docs/MIGRATIONS.md) · [QUALITY.md](./docs/QUALITY.md) · [DEVELOPMENT_LOG.md](./docs/DEVELOPMENT_LOG.md) · [DEVELOPMENT_DIARY.md](./docs/DEVELOPMENT_DIARY.md) · [DEVELOPMENT_LOG_RESTART.md](./docs/archive/DEVELOPMENT_LOG_RESTART.md) · [DEVELOPMENT_DIARY_RESTART.md](./docs/archive/DEVELOPMENT_DIARY_RESTART.md) |
| Domain | [API.md](./docs/API.md) · [domain-scope](./docs/domain/domain-scope.md) · [crud-endpoint-plan](./docs/domain/crud-endpoint-plan.md) |
| Containers | [docker-guide](./docs/containers/docker-guide.md) · [compose-guide](./docs/containers/compose-guide.md) |
| Kubernetes | [k8s-concept-map](./docs/kubernetes/k8s-concept-map.md) · [helm-guide](./docs/kubernetes/helm-guide.md) |
| Istio | [readiness](./docs/istio/readiness.md) · [traffic](./docs/istio/traffic.md) · [security](./docs/istio/security.md) |
| CI/CD | [github-actions](./docs/cicd/github-actions.md) |
| Terraform | [scope-and-boundary](./docs/terraform/scope-and-boundary.md) · [flow-integration](./docs/terraform/flow-integration.md) |
| Roadmap | [roadmap index](./docs/roadmap/README.md) · [phase 1 step 1 scope](./docs/roadmap/phase-1/step-1-minimum-test-scope.md) · [phase 1 step 2 layer decision](./docs/roadmap/phase-1/step-2-first-test-layer.md) · [phase 1 step 3 test environment](./docs/roadmap/phase-1/step-3-clean-test-environment.md) · [phase 1 step 4 green slice](./docs/roadmap/phase-1/step-4-smallest-green-slice.md) · [phase 1 step 5 songs CRUD](./docs/roadmap/phase-1/step-5-songs-crud-tests.md) · [phase 1 step 6 playlists CRUD](./docs/roadmap/phase-1/step-6-playlists-crud-tests.md) · [phase 1 step 7 relationship tests](./docs/roadmap/phase-1/step-7-playlist-song-relationship-tests.md) · [phase 1 step 8 negative tests](./docs/roadmap/phase-1/step-8-negative-tests.md) · [phase 1 step 9 local stability](./docs/roadmap/phase-1/step-9-local-test-stability.md) · [phase 1 step 10 ci integration](./docs/roadmap/phase-1/step-10-ci-test-integration.md) · [phase 2 step 11 migration ownership](./docs/roadmap/phase-2/step-11-migration-ownership.md) · [phase 2 step 12 baseline strategy](./docs/roadmap/phase-2/step-12-baseline-migration-strategy.md) · [phase 2 step 13 migration structure](./docs/roadmap/phase-2/step-13-migration-structure.md) · [phase 2 step 14 clean upgrade](./docs/roadmap/phase-2/step-14-clean-db-upgrade-validation.md) · [phase 2 step 15 reduce create_all](./docs/roadmap/phase-2/step-15-reduce-create-all-responsibility.md) · [phase 2 step 16 migration workflow docs](./docs/roadmap/phase-2/step-16-document-migration-workflow.md) |

---

## Tests

Contract tests are implemented and run locally with:

```bash
./scripts/verify-local-tests.sh 3
```

CI also runs API contract tests on pull requests in the validation job (`python3 -m pytest -q tests`).

---

## Notes

- Schema evolution is migration-owned. Startup does not create/update schema anymore.
- Baseline migration revision is `abff2336451a` and clean upgrade flow has been validated from base to head.
- Startup validates DB reachability and required tables; missing schema must be applied via migrations (`alembic upgrade head`).
- DB startup retry is configurable via `STARTUP_DB_MAX_RETRIES` (default `20`) and `STARTUP_DB_RETRY_SECONDS` (default `2`). Kubernetes startup behaviour is also controlled by `api.probes.startup` in `helm/music-platform/values.yaml`.
