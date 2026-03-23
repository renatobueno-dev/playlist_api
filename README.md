# Music Platform API

![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Helm-326CE5?logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![Istio](https://img.shields.io/badge/Istio-service_mesh-466BB0?logo=istio&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)

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
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── requirements.txt
├── app/                           # FastAPI application
│   ├── main.py
│   ├── database.py
│   ├── models/      (song, playlist, playlist_song, base)
│   ├── schemas/     (song, playlist)
│   ├── routes/      (health, songs, playlists)
│   └── services/    (song_service, playlist_service)
├── helm/music-platform/           # Helm chart
│   ├── Chart.yaml / values.yaml
│   └── templates/   (deployment, service, statefulset, configmap, secret, serviceaccounts)
├── k8s/istio/                     # Istio manifests
│   ├── traffic-management.yaml
│   └── security-policies.yaml
├── terraform/                     # Environment foundation
│   ├── main.tf / variables.tf / outputs.tf / versions.tf
├── docs/                          # Reference documentation (by topic)
│   ├── README.md                  # Navigation index
│   ├── domain/      (domain-scope, crud-endpoint-plan)
│   ├── containers/  (docker-guide)
│   ├── kubernetes/  (k8s-concept-map, helm-guide)
│   ├── istio/       (readiness, traffic, security)
│   ├── cicd/        (github-actions)
│   └── terraform/   (scope, helm-boundary, min-scope, flow-integration)
```

**Request layer flow:** `routes` → `schemas` → `services` → `models` → `database`

---

## How to run locally

1. Create and activate a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Windows: .\venv\Scripts\activate
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Start the server (uses SQLite by default — no database needed):
   ```bash
   uvicorn app.main:app --reload
   ```
   To use PostgreSQL instead, set `DATABASE_URL` before starting (see [SETUP_AND_QUALITY.md](docs/SETUP_AND_QUALITY.md)).

- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

## How to run with Docker

```bash
cp .env.example .env
docker compose up --build
```

API: `http://localhost:8000/`

---

## API endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/` | API status message |
| `GET` | `/health` | Service healthcheck |
| `GET/POST` | `/songs/` | List / create songs |
| `GET/PATCH/DELETE` | `/songs/{id}` | Get / update / delete song |
| `GET/POST` | `/playlists/` | List / create playlists |
| `GET/PATCH/DELETE` | `/playlists/{id}` | Get / update / delete playlist |
| `POST` | `/playlists/{id}/songs/{song_id}` | Link song to playlist |
| `DELETE` | `/playlists/{id}/songs/{song_id}` | Unlink song from playlist |

Playlist `PATCH` accepts optional `song_ids` — if provided, links are replaced; if omitted, unchanged.
Non-existent IDs return `404`.

---

## Documentation

Full reference in [`docs/`](./docs/README.md):

| Topic | Files |
| --- | --- |
| Project-wide | [CHANGELOG.md](./CHANGELOG.md) · [ARCHITECTURE.md](./docs/ARCHITECTURE.md) · [SETUP_AND_QUALITY.md](./docs/SETUP_AND_QUALITY.md) · [DEVELOPMENT_LOG.md](./docs/DEVELOPMENT_LOG.md) |
| Domain | [domain-scope](./docs/domain/domain-scope.md) · [crud-endpoint-plan](./docs/domain/crud-endpoint-plan.md) |
| Containers | [docker-guide](./docs/containers/docker-guide.md) |
| Kubernetes | [k8s-concept-map](./docs/kubernetes/k8s-concept-map.md) · [helm-guide](./docs/kubernetes/helm-guide.md) |
| Istio | [readiness](./docs/istio/readiness.md) · [traffic](./docs/istio/traffic.md) · [security](./docs/istio/security.md) |
| CI/CD | [github-actions](./docs/cicd/github-actions.md) |
| Terraform | [scope](./docs/terraform/scope.md) · [helm-boundary](./docs/terraform/helm-boundary.md) · [min-scope](./docs/terraform/min-scope.md) · [flow-integration](./docs/terraform/flow-integration.md) |

---

## Tests

> **Under development.**

---

## Notes

- Schema is initialised via `Base.metadata.create_all()`. Alembic migration tracking is under development.
- DB startup retry is configurable via `STARTUP_DB_MAX_RETRIES` (default `20`) and `STARTUP_DB_RETRY_SECONDS` (default `2`). Kubernetes startup behaviour is also controlled by `api.probes.startup` in `helm/music-platform/values.yaml`.
