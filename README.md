# Checkpoint Level 3 - Stage 1

Minimal FastAPI + SQLAlchemy structure for a music platform domain.

## Scope defined

- `Song` resource
- `Playlist` resource
- Many-to-many relationship through `playlist_songs`

See [DOMAIN_SCOPE.md](./DOMAIN_SCOPE.md) for detailed fields and relationship decisions.

## Project structure

```text
.
├── .github/
│   └── workflows/
│       └── deploy.yml
├── .dockerignore
├── .env.example
├── .gitignore
├── Dockerfile
├── DOMAIN_SCOPE.md
├── README.md
├── STAGE_2_DOCKER_GUIDE.md
├── STAGE_3_HELM_GUIDE.md
├── STAGE_3_K8S_CONCEPT_MAP.md
├── STAGE_4_GITHUB_ACTIONS_GUIDE.md
├── STAGE_4_ISTIO_READINESS_GUIDE.md
├── STAGE_4_ISTIO_SECURITY_GUIDE.md
├── STAGE_4_TERRAFORM_HELM_BOUNDARY_GUIDE.md
├── STAGE_4_TERRAFORM_MIN_SCOPE_GUIDE.md
├── STAGE_4_TERRAFORM_SCOPE_GUIDE.md
├── STAGE_4_ISTIO_TRAFFIC_GUIDE.md
├── docker-compose.yml
├── helm/
├── requirements.txt
└── app
    ├── __init__.py
    ├── database.py
    ├── main.py
    ├── models
    │   ├── __init__.py
    │   ├── base.py
    │   ├── playlist.py
    │   ├── playlist_song.py
    │   └── song.py
    ├── routes
    │   ├── __init__.py
    │   ├── health.py
    │   ├── playlists.py
    │   └── songs.py
    ├── schemas
    │   ├── __init__.py
    │   ├── playlist.py
    │   └── song.py
    └── services
        ├── __init__.py
        ├── playlist_service.py
        └── song_service.py
```

### What each part does

| Path | Responsibility |
| --- | --- |
| `DOMAIN_SCOPE.md` | Defines the domain model and relationship decisions for `Song` and `Playlist`. |
| `requirements.txt` | Lists runtime dependencies (`fastapi`, `uvicorn`, `sqlalchemy`, `psycopg`). |
| `Dockerfile` | Defines the container runtime for the API service. |
| `docker-compose.yml` | Orchestrates API + PostgreSQL services for local multi-container runs. |
| `.env.example` | Documents environment variables for Compose configuration. |
| `.github/workflows/deploy.yml` | GitHub Actions workflow for validation, image build/push, and automated deploy. |
| `STAGE_2_DOCKER_GUIDE.md` | Step-by-step Stage 2 guide (A to E) with validation and troubleshooting checks. |
| `STAGE_3_K8S_CONCEPT_MAP.md` | Conceptual translation from Docker/Compose to Kubernetes/Helm resources. |
| `STAGE_3_HELM_GUIDE.md` | Helm chart structure and install/lint commands for Stage 3 Phase 3. |
| `STAGE_4_GITHUB_ACTIONS_GUIDE.md` | Stage 4 Phase 4 CI/CD automation model with triggers, deploy steps, and logs. |
| `STAGE_4_ISTIO_READINESS_GUIDE.md` | Stage 4 Phase 1 Istio readiness checklist and validation flow. |
| `STAGE_4_ISTIO_SECURITY_GUIDE.md` | Stage 4 Phase 3 security policy model and Istio protection rules. |
| `STAGE_4_TERRAFORM_HELM_BOUNDARY_GUIDE.md` | Stage 4 Phase 5 Step 2 separation contract between Terraform and Helm ownership. |
| `STAGE_4_TERRAFORM_MIN_SCOPE_GUIDE.md` | Stage 4 Phase 5 Step 3 smallest valid Terraform scope definition for this project. |
| `STAGE_4_TERRAFORM_SCOPE_GUIDE.md` | Stage 4 Phase 5 Step 1 Terraform ownership boundary and responsibility scope. |
| `STAGE_4_ISTIO_TRAFFIC_GUIDE.md` | Stage 4 Phase 2 traffic entry path and Istio routing setup. |
| `helm/music-platform` | Helm chart containing metadata, configurable values, and Kubernetes templates. |
| `app/main.py` | API entry point, application creation, router registration, and startup DB initialization with retry. |
| `app/database.py` | SQLAlchemy engine/session setup and FastAPI dependency provider (`get_session`). |
| `app/models/base.py` | Shared SQLAlchemy declarative base class. |
| `app/models/song.py` | `Song` ORM model and relationship to playlists. |
| `app/models/playlist.py` | `Playlist` ORM model and relationship to songs. |
| `app/models/playlist_song.py` | Association table model for the many-to-many relation and `added_at` metadata. |
| `app/schemas/song.py` | Pydantic API contracts for songs: `SongCreate`, `SongUpdate`, `SongRead`. |
| `app/schemas/playlist.py` | Pydantic API contracts for playlists: `PlaylistCreate`, `PlaylistUpdate`, `PlaylistRead`. |
| `app/routes/health.py` | Healthcheck endpoint for service status. |
| `app/routes/songs.py` | HTTP endpoints for full song CRUD operations. |
| `app/routes/playlists.py` | HTTP endpoints for full playlist CRUD operations. |
| `app/services/song_service.py` | Database operations used by song routes (create/read/update/delete). |
| `app/services/playlist_service.py` | Database operations used by playlist routes (create/read/update/delete). |

### Layer flow

Request flow follows this order:

1. `routes/*` receives and validates HTTP input.
2. `schemas/*` enforces input/output contracts.
3. `services/*` executes business/database operations.
4. `models/*` maps Python objects to database tables.
5. `database.py` manages sessions used across route handlers.

## Run locally

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Start the API:

```bash
uvicorn app.main:app --reload
```

4. Open docs:

- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

## Stage 2 containerization

Detailed execution plan for Stage 2 Steps A to E:
- [STAGE_2_DOCKER_GUIDE.md](./STAGE_2_DOCKER_GUIDE.md)

## Stage 3 Kubernetes planning

Conceptual translation for Phase 2 (before writing manifests):
- [STAGE_3_K8S_CONCEPT_MAP.md](./STAGE_3_K8S_CONCEPT_MAP.md)

## Stage 3 Helm chart

Phase 3 chart structure and usage:
- [STAGE_3_HELM_GUIDE.md](./STAGE_3_HELM_GUIDE.md)

## Stage 4 Runtime And Automation

Phase 1 readiness checklist:
- [STAGE_4_ISTIO_READINESS_GUIDE.md](./STAGE_4_ISTIO_READINESS_GUIDE.md)

Phase 2 traffic path and routing setup:
- [STAGE_4_ISTIO_TRAFFIC_GUIDE.md](./STAGE_4_ISTIO_TRAFFIC_GUIDE.md)

Phase 3 security policies:
- [STAGE_4_ISTIO_SECURITY_GUIDE.md](./STAGE_4_ISTIO_SECURITY_GUIDE.md)

Phase 4 GitHub Actions automation:
- [STAGE_4_GITHUB_ACTIONS_GUIDE.md](./STAGE_4_GITHUB_ACTIONS_GUIDE.md)

Phase 5 Terraform scope definition (Step 1):
- [STAGE_4_TERRAFORM_SCOPE_GUIDE.md](./STAGE_4_TERRAFORM_SCOPE_GUIDE.md)

Phase 5 Terraform vs Helm separation (Step 2):
- [STAGE_4_TERRAFORM_HELM_BOUNDARY_GUIDE.md](./STAGE_4_TERRAFORM_HELM_BOUNDARY_GUIDE.md)

Phase 5 minimum valid Terraform scope (Step 3):
- [STAGE_4_TERRAFORM_MIN_SCOPE_GUIDE.md](./STAGE_4_TERRAFORM_MIN_SCOPE_GUIDE.md)

## Implemented endpoints (current)

- `GET /`
- `GET /health`
- `GET /songs/`
- `POST /songs/`
- `GET /songs/{song_id}`
- `PATCH /songs/{song_id}`
- `DELETE /songs/{song_id}`
- `GET /playlists/`
- `POST /playlists/`
- `GET /playlists/{playlist_id}`
- `PATCH /playlists/{playlist_id}`
- `DELETE /playlists/{playlist_id}`
- `POST /playlists/{playlist_id}/songs/{song_id}`
- `DELETE /playlists/{playlist_id}/songs/{song_id}`

## CRUD planning reference

Initial planning notes are documented in [CRUD_ENDPOINT_PLAN.md](./CRUD_ENDPOINT_PLAN.md).

## Relationship behavior (validated)

- Playlist creation accepts an optional `song_ids` list in `PlaylistCreate`.
- Playlist update accepts optional `song_ids` in `PlaylistUpdate`:
  - if provided, playlist-song links are replaced by the provided list
  - if omitted, links remain unchanged
- Songs can also be linked/unlinked later using:
  - `POST /playlists/{playlist_id}/songs/{song_id}`
  - `DELETE /playlists/{playlist_id}/songs/{song_id}`
- Playlist responses embed songs (`PlaylistRead.songs`).
- Referencing nonexistent songs in `song_ids` returns `404`.
- Linking/unlinking with nonexistent playlist/song IDs returns `404`.
- Unlinking a song that is not linked to the playlist returns `404`.

## Current database note

This project currently uses `Base.metadata.create_all(...)` (no migration tool yet).
If you change model columns after creating `music.db`, recreate the database file
or add migrations (for example with Alembic) in the next stage.

## Startup resilience knobs

For environments where DB startup can be slower than API boot, use:

- `STARTUP_DB_MAX_RETRIES` (default: `20`)
- `STARTUP_DB_RETRY_SECONDS` (default: `2`)

In Kubernetes, API startup behavior is also controlled by Helm probe values in `helm/music-platform/values.yaml` under `api.probes.startup`.
