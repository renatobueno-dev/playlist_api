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

Implemented educational backend project focused on consolidating real API, database, and deployment practices with FastAPI. Domain: `Song` + `Playlist` with many-to-many through `playlist_songs`, built across 4 progressive infrastructure stages: local → Docker/Compose → Kubernetes/Helm → Istio/Terraform/CI.

- REST API with a simple but representative domain (songs and playlists)
- Migration-managed schema lifecycle with Alembic baseline and tracked upgrade flow
- Contract-tested request/response behavior for health, songs, playlists, and relationship endpoints
- Kubernetes workload management with Helm and Istio service mesh
- Infrastructure as code with Terraform
- Automated CI/CD pipeline with GitHub Actions

> 💡 **Want to understand the development process?** See [Development Log](docs/DEVELOPMENT_LOG.md) for decisions, corrections, and reasoning recorded during each stage.

## ⚠️ Security note

This repository is for study. Before using in production:

- Use strong, real secrets in environment variables — never commit `.env`
- Set `DATABASE_URL` and all credentials via injected secrets, not hardcoded defaults
- Restrict CORS origins and rotate all credentials before exposure
- Authentication and authorization are intentionally out of scope in the current study version, so all API endpoints are unauthenticated by design

---

## Project structure

```text
.
├── .editorconfig
├── .github/workflows/deploy.yml   # CI/CD pipeline
├── .markdownlint-cli2.yaml
├── .pre-commit-config.yaml
├── .prettierignore
├── .prettierrc.json
├── .yamllint.yml
├── CHANGELOG.md
├── alembic.ini
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── requirements.txt
├── requirements-dev.txt
├── ruff.toml
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
├── scripts/                       # Quality, test, and deployment helpers
│   ├── check-quality.sh
│   ├── check-text-hygiene.py
│   ├── format-all.sh
│   ├── render-istio-manifests.sh
│   ├── run-quality-tool.sh
│   └── verify-local-tests.sh
├── terraform/                     # Environment foundation
│   ├── main.tf / variables.tf / outputs.tf / versions.tf / backend.tf
├── tests/                         # API contract test suite
│   ├── conftest.py
│   └── test_*.py
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

5. Verify the contract test suite:

   ```bash
   ./.venv/bin/python -m pytest -q tests
   ```

Runtime rule: `DATABASE_URL` is required, and startup validates schema presence only. Table creation and schema evolution must happen through migrations.

- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

## How to run with Docker

The migration step below still runs from your host Python environment. If you have not already done the local setup once, create `.venv` and install the project dependencies first.

```bash
cp .env.example .env
# Load the same values Compose will use into the current shell
set -a
source .env
set +a
docker compose up -d db
DATABASE_URL="${DATABASE_URL_HOST}" ./.venv/bin/alembic upgrade head
docker compose up -d api
```

API: `http://localhost:<API_PORT>/` where `API_PORT` defaults to `8000`.

The API container expects a valid `DATABASE_URL` and a migrated database. If the schema is missing, startup fails fast with a migration instruction instead of creating tables automatically. Keep `.env` `DATABASE_URL` values URL-safe if the password includes reserved URL characters.

---

## API endpoints

| Method             | Path                                       | Description                    |
| ------------------ | ------------------------------------------ | ------------------------------ |
| `GET`              | `/`                                        | API status message             |
| `GET`              | `/health`                                  | Service healthcheck            |
| `GET/POST`         | `/songs/`                                  | List / create songs            |
| `GET/PATCH/DELETE` | `/songs/{song_id}`                         | Get / update / delete song     |
| `GET/POST`         | `/playlists/`                              | List / create playlists        |
| `GET/PATCH/DELETE` | `/playlists/{playlist_id}`                 | Get / update / delete playlist |
| `POST`             | `/playlists/{playlist_id}/songs/{song_id}` | Link song to playlist          |
| `DELETE`           | `/playlists/{playlist_id}/songs/{song_id}` | Unlink song from playlist      |

Playlist `PATCH` accepts optional `song_ids` — if provided, links are replaced; if omitted, unchanged.
Repeated `song_ids` are silently deduplicated before links are resolved.
Non-existent IDs return `404`.
All endpoints are currently unauthenticated in this study project.

---

## Documentation

Full reference in [`docs/`](./docs/README.md):

| Topic              | Files                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Project-wide       | [CHANGELOG.md](./CHANGELOG.md) · [ARCHITECTURE.md](./docs/ARCHITECTURE.md) · [INFRA_DECISIONS.md](./docs/INFRA_DECISIONS.md) · [SETUP.md](./docs/SETUP.md) · [SECRETS_OWNERSHIP.md](./docs/SECRETS_OWNERSHIP.md) · [MIGRATIONS.md](./docs/MIGRATIONS.md) · [QUALITY.md](./docs/QUALITY.md) · [RELEASE_PLAN.md](./docs/RELEASE_PLAN.md) · [DEVELOPMENT_LOG.md](./docs/DEVELOPMENT_LOG.md) · [DEVELOPMENT_DIARY.md](./docs/DEVELOPMENT_DIARY.md) · [DEVELOPMENT_LOG_RESTART.md](./docs/archive/DEVELOPMENT_LOG_RESTART.md) · [DEVELOPMENT_DIARY_RESTART.md](./docs/archive/DEVELOPMENT_DIARY_RESTART.md) |
| Domain             | [API.md](./docs/API.md) · [domain-scope](./docs/domain/domain-scope.md) · [crud-endpoint-plan](./docs/domain/crud-endpoint-plan.md)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Containers         | [docker-guide](./docs/containers/docker-guide.md) · [compose-guide](./docs/containers/compose-guide.md)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Kubernetes         | [k8s-concept-map](./docs/kubernetes/k8s-concept-map.md) · [helm-guide](./docs/kubernetes/helm-guide.md)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Istio              | [readiness](./docs/istio/readiness.md) · [traffic](./docs/istio/traffic.md) · [security](./docs/istio/security.md)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CI/CD              | [github-actions](./docs/cicd/github-actions.md)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Terraform          | [scope-and-boundary](./docs/terraform/scope-and-boundary.md) · [flow-integration](./docs/terraform/flow-integration.md) · [state-management-policy](./docs/terraform/state-management-policy.md)                                                                                                                                                                                                                                                                                                                                                                                                       |
| Quality / analysis | [QUALITY.md](./docs/QUALITY.md) · [QUALITY_IMPLEMENTATION.md](./docs/QUALITY_IMPLEMENTATION.md) · [SECURITY_TOOLCHAIN.md](./docs/SECURITY_TOOLCHAIN.md) · [STATIC_ANALYSIS.md](./docs/STATIC_ANALYSIS.md) · [static-analysis steps](./docs/static-analysis/README.md)                                                                                                                                                                                                                                                                                                                                  |
| Validation         | [lifecycle validation](./docs/LIFECYCLE_VALIDATION.md) — final A1 → A2 → A3 → A4 → B1 verification record across local, tests, Docker, Kubernetes, and Istio ingress                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| Roadmap            | [roadmap index](./docs/roadmap/README.md) — canonical step-by-step execution record for tests, migrations, secret flow, Terraform, and platform guardrails                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| Fixes              | [fixes index](./docs/fixes/README.md) — post-checkpoint remediation record for the loose ends that were closed after the core stage work                                                                                                                                                                                                                                                                                                                                                                                                                                                               |

---

## Tests

Contract tests are implemented and run locally with:

```bash
./scripts/verify-local-tests.sh 3
```

CI also runs the contract suite in the dedicated runtime-validation job.

---

## Quality

Repo-wide formatting and linting are available through the layered quality scripts:

```bash
./scripts/format-all.sh
./scripts/check-quality.sh fast
./scripts/check-quality.sh python
./scripts/check-quality.sh security
./scripts/check-quality.sh infra
./scripts/check-quality.sh runtime
./scripts/check-quality.sh all
```

`./scripts/check-quality.sh` is read-only. If you want the repo rewritten into the expected format, use `./scripts/format-all.sh`.

Local prerequisites by layer:

- `fast` and `python` assume the project `.venv` is installed with the repo dependencies.
- `security` also needs Docker locally because the `lychee` wrapper runs through a container image.
- `infra` also needs Docker, Helm, and Terraform available on your machine.
- `runtime` also needs Docker because the layer builds and validates the container image.

Python quality has explicit boundaries in this project:

- Ruff = formatting + fast lint
- Pylint = primary static-analysis baseline
- Radon = primary complexity + maintainability baseline

Ruff does **not** replace Pylint or Radon here.

For the intended **full-quality** standard, the main Python cleanup target is the findings from default `pylint` and default `radon`. The quality runner uses that default baseline directly, and the other tools in this repo are complementary refinements for formatting, docs, shell, Docker, YAML, and infrastructure hygiene.

The repo also now has a dedicated security layer:

- `gitleaks`
- `pip-audit`
- `lychee`
- tuned `bandit`

The rollout plan and the staged `trivy` follow-up are documented in [SECURITY_TOOLCHAIN.md](./docs/SECURITY_TOOLCHAIN.md).

---

## Notes

- Schema evolution is migration-owned. Startup does not create/update schema anymore.
- Baseline migration revision is `abff2336451a` and clean upgrade flow has been validated from base to head.
- Startup validates DB reachability and required tables; missing schema must be applied via migrations (`alembic upgrade head`).
- DB startup retry is configurable via `STARTUP_DB_MAX_RETRIES` (default `20`) and `STARTUP_DB_RETRY_SECONDS` (default `2`). Kubernetes startup behaviour is also controlled by `api.probes.startup` in `helm/music-platform/values.yaml`.
- The Helm chart now defaults to `api.replicaCount: 2` for a more production-like API posture. For lightweight local clusters, you can still override it with `--set api.replicaCount=1`.
