# Changelog

All notable changes to this project are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added

- Repository-wide full-quality tooling foundation with Ruff, Prettier, markdownlint, yamllint, shfmt, ShellCheck, actionlint, hadolint, dotenv-linter, pre-commit hooks, and helper scripts for local quality workflows.
- Dedicated quality/security implementation guides documenting the layered validation model and the staged security-toolchain rollout.
- `docs/STATIC_ANALYSIS.md` guide covering the full pylint/radon workflow, suppression policy, and maintenance baseline.
- `docs/static-analysis/` directory with 7 step-by-step files documenting the complete static-analysis adoption path (baseline → findings → docstrings → suppressions → CI enforcement decision → maintenance).

### Changed

- Python quality now targets the default `pylint` and default `radon` baseline directly, with codebase cleanup aligned to those reports.
- GitHub Actions validation is now split into `fast-quality`, `python-quality`, `security-validation`, and `runtime-validation` before deploy.
- All CI jobs pinned to `ubuntu-24.04` runner for reproducible workflow execution.
- Repository docs were synchronized with the current quality model, CI layers, and static-analysis history, including the historical transition from local-only static analysis to CI enforcement.
- Docker Compose now consumes explicit database URLs instead of assembling them from raw `POSTGRES_*` variables, and the setup docs now distinguish container-facing and host-facing connection strings.
- The Helm chart now defaults to two API replicas, with docs updated to describe the local override path for lightweight clusters.
- Contract test suite expanded from ~14 to 46 focused cases through radon hotspot reduction, splitting complex test helpers into independent parameterized cases.

### Fixed

- Post-split fast-quality regressions in shell tooling and documentation formatting were cleaned up so `./scripts/check-quality.sh all` passes end to end again.
- API docs now explicitly describe the current unauthenticated project scope and the deduplication behavior for repeated `song_ids` in playlist create/update flows.
- Song and playlist DELETE handlers standardized to explicit `Response(status_code=204)` for consistent return style across all delete routes.

### Security

- Added enforced repository security validation with `gitleaks`, `pip-audit`, `lychee`, and tuned `bandit`, while documenting `trivy` as the next staged hardening phase.
- Dockerfile base image SHA-pinned (`python:3.12-slim@sha256:3d5ed973e45820f5ba5e46bd065bd88b3a504ff0724d85980dcd05eab361fcf4`) for supply-chain reproducibility.
- Helm DB image SHA-pinned (`postgres:16-alpine@sha256:20edbde7749f822887a1a022ad526fde0a47d6b2be9a8364433605cf65099416`) for consistent base image across chart deployments.
- Docker Compose DB image SHA-pinned using the same digest as the Helm chart.

## [1.7.0] — 2026-03-31

### Added

- API contract test suite covering health, songs, playlists, playlist-song links, and environment setup, plus a local stability runner script.
- Alembic baseline migration workflow with tracked migration files and migration-owned schema lifecycle.
- Terraform namespace guardrail baseline for safer namespace policy management.

### Changed

- Application startup now follows a migration-first flow: database reachability and required schema are validated at startup, but schema creation/evolution must happen through Alembic migrations.
- Validation workflow now installs test dependencies and runs API contract tests before the compile/build checks.
- Setup, validation, CI, infrastructure, and operational guides were aligned to the current runtime behavior and release process.

### Fixed

- CI deploy now enforces use of an external runtime secret and verifies required secret keys before Helm deploy.

### Security

- Kubernetes runtime and mesh namespace baseline were hardened with stricter runtime defaults and safer namespace posture alignment.

## [1.6.1] — 2026-03-28

### Added

- Database URL validation now fails fast with clear errors for malformed `DATABASE_URL` values and unsupported schemes (`sqlite`/`postgresql` only).
- Structured service-layer logging was added for song and playlist operations (`DEBUG` for list flows, `INFO` for mutations, `WARNING` for missing-song cases).
- Terraform variable validation was added for kubeconfig path, namespace naming, and Pod Security settings.
- Deploy pipeline now removes kubeconfig at job end to avoid runner credential persistence.

### Changed

- Documentation was reorganized and synchronized across setup, architecture, API reference, CI/CD, and Istio traffic guides to match current implementation behavior.
- Namespace handling was centralized across Terraform, workflow environment variables, and rendered Istio manifests.
- Terraform Kubernetes provider constraint was tightened to patch-level (`~> 2.38.0`) and startup retry controls were exposed in environment examples.
- Terraform backend was moved from local state file to Kubernetes backend and backend namespace was hardened to `kube-system`.
- Helm/runtime defaults were tightened: safer startup probe defaults, explicit storage class default (`standard`), and release metadata alignment.
- Playlist model relationships were simplified around the association model to avoid duplicate relationship paths.

### Fixed

- CI validation now explicitly installs Python 3.12, and manual deploy runs are gated to `main`.
- Playlist-song endpoints now return consistent status codes (`201` on link, `204` on unlink) with standardized not-found details.
- Istio manifest rendering now escapes substitution values and fails early when unresolved placeholders remain.
- Helm NOTES now references the correct API service helper name generated by the chart.
- Container healthcheck timeout was increased to reduce false-positive restarts during slow startup windows.

### Security

- Container and pod runtime hardening: non-root execution, seccomp profile, dropped capabilities, and read-only root filesystem for the API container.
- Namespace-level Pod Security posture was tightened with enforce/warn/audit labels.
- Secret handling was hardened: no weak default DB password, stronger generated credentials, URL-encoding before `DATABASE_URL` composition, and preservation of existing secrets on upgrade.
- Istio traffic hardening now includes a `DestinationRule` resilience baseline plus HTTPS redirect/TLS termination at the ingress gateway.
- CI/CD supply-chain posture improved with pinned action SHAs and tighter version pinning for runtime/build dependencies.

## [1.6.0] — 2026-03-23

### Added

- Architecture reference guide covering data model, layer structure, schema design, database, service layer, startup resilience, Kubernetes, Istio, Terraform, and CI/CD decisions (`docs/ARCHITECTURE.md`)
- Setup and quality guide covering environment variables, local/Docker/Kubernetes setup steps, and CI overview (`docs/SETUP_AND_QUALITY.md`)
- Development log recording the reasoning, decisions, and corrections made at each project stage (`docs/DEVELOPMENT_LOG.md`)
- Documentation navigation index linking all 17 topic files (`docs/README.md`)
- `.gitignore` covering Python cache, virtual environments, IDE settings, local databases, Terraform state, and environment files
- Terraform provider lock file (`terraform/.terraform.lock.hcl`)

### Changed

- `README.md` rewritten as a concise entry point: badges, purpose, security note, project structure, setup commands, endpoint table, documentation links, and honest test status
- 13 topic guides reorganised from root into `docs/` subdirectories by topic (`domain/`, `containers/`, `kubernetes/`, `istio/`, `cicd/`, `terraform/`)
- `Stage N -`, `(Phase N)`, and `(Step N)` prefixes removed from H1 headings across all 13 topic guides
- AI workflow section in `docs/DEVELOPMENT_LOG.md` expanded to five conversations with correct model names and roles
- Test sections in `README.md` and `docs/SETUP_AND_QUALITY.md` marked as under development
- Alembic migration notes in `README.md` and `docs/ARCHITECTURE.md` updated from aspirational phrasing to under development

### Removed

- Duplicate content from `docs/ARCHITECTURE.md`: Terraform ownership matrix, Istio layer table, and CI binary collision steps
- Duplicate CI job step list from `docs/SETUP_AND_QUALITY.md` — replaced with a summary and reference to `docs/cicd/github-actions.md`
- Planned test structure, commands, and priority test table from `docs/SETUP_AND_QUALITY.md`

### Fixed

- Python version badge corrected from `3.11` to `3.12` to match `Dockerfile` base image (`python:3.12-slim`)
- `MissingSongsError` HTTP status documented as `422` in `docs/ARCHITECTURE.md` — corrected to `404`, matching the actual route response
- `DATABASE_URL` assembly example missing the `:5432/` port segment in `docs/SETUP_AND_QUALITY.md` — corrected
- `POST /playlists/` error codes in `docs/domain/crud-endpoint-plan.md` listed only `422` — corrected to `404, 422` (`404` for non-existent `song_ids`, `422` for schema validation)
- `serviceaccounts.yaml` missing from the Helm chart structure in `docs/kubernetes/helm-guide.md` — added (template created during Istio phase was not reflected in the guide)
- Stage 4 phase numbering corrected in `docs/DEVELOPMENT_LOG.md`: Terraform was labelled Phase 5 and CI/CD Phase 4 — swapped to the correct order (Terraform → Phase 4, CI/CD → Phase 5)
- Terraform binary collision error detail moved from the CI/CD phase body to the dedicated errors section in `docs/DEVELOPMENT_LOG.md`
- CI section link display text in `docs/SETUP_AND_QUALITY.md` corrected to match the filename-only pattern used elsewhere in the file

## [1.5.0] — 2026-03-20

### Added

- Automated CI/CD pipeline (`.github/workflows/deploy.yml`) with two jobs:
  - **Validate**: Python compile check, Docker build, Helm lint and template render, Terraform `fmt` / `init` / `validate`
  - **Deploy**: image build and push to GHCR (`ghcr.io/<owner>/music-platform-api:<sha>` and `:latest`), Terraform apply for namespace baseline, Helm upgrade, Istio manifests apply, rollout verification
- Deploy guard: deploy steps are skipped with an explicit `::notice::` when `KUBE_CONFIG_DATA` secret is absent — safe to run in forks or environments without a configured cluster
- CLI versions pinned (`kubectl v1.30.0`, Helm `v3.15.4`, Terraform `1.6.6`) with retry-enabled downloads for transient network failures
- Automatic `terraform import` step in the deploy job to handle pre-existing namespaces without causing state conflicts

### Fixed

- Terraform binary install failing with `error: cannot delete old terraform / Is a directory` — caused by the `terraform/` project directory conflicting with the binary name during unzip; fixed by extracting into a temporary directory

## [1.4.0] — 2026-03-20

### Added

- Terraform foundation (`terraform/`) managing the `music-platform` Kubernetes namespace lifecycle and the `istio-injection=enabled` label as a platform prerequisite
- Configurable via `kubeconfig_path`, `namespace_name`, `namespace_labels`, and `namespace_annotations` variables
- Outputs `namespace_name` and `namespace_labels` for downstream reference
- Provider and version constraints: Terraform `>= 1.6.0`, `hashicorp/kubernetes ~> 2.38.0`

## [1.3.0] — 2026-03-20

### Added

- Istio traffic entry: `Gateway/playcatch-gateway` (host `playcatch.local`, port 80) and `VirtualService/playcatch-api-ingress` routing all traffic to the API on port `8000` (`k8s/istio/traffic-management.yaml`)
- Istio security policies (`k8s/istio/security-policies.yaml`):
  - `STRICT` mTLS enforced across the entire `music-platform` namespace
  - API port `8000` accessible only from `istio-system` and `music-platform` namespaces
  - DB port `5432` accessible only from the API service account principal (`cluster.local/ns/music-platform/sa/music-platform-api-sa`)

### Changed

- Dedicated `ServiceAccount` resources added to the Helm chart (`music-platform-api-sa`, `music-platform-db-sa`) so Istio `AuthorizationPolicy` rules can use principal identity rather than just namespace
- API `Deployment` and DB `StatefulSet` templates updated to reference their respective service accounts

## [1.2.0] — 2026-03-19

### Added

- Helm chart (`helm/music-platform/`) for repeatable Kubernetes deployment:
  - API `Deployment` with a three-probe strategy (`startupProbe` / `readinessProbe` / `livenessProbe`) — all thresholds configurable via `api.probes` in `values.yaml`
  - PostgreSQL `StatefulSet` with a `PersistentVolumeClaim` (`1Gi` default storage)
  - `ClusterIP` services for API (port `8000`) and database (port `5432`)
  - `ConfigMap` assembling `DATABASE_URL` from chart values; `Secret` holding PostgreSQL credentials
- Centralised `values.yaml` covering image tag, replica count, service ports, probe thresholds, DB credentials, and persistence size

## [1.1.0] — 2026-03-19

### Added

- Docker image for the API (`python:3.12-slim` base, port `8000`, `uvicorn` entrypoint)
- Docker Compose setup with `api` and `db` (`postgres:16-alpine`) services and `.env.example` for local configuration
- PostgreSQL healthcheck (`pg_isready`) with `depends_on: condition: service_healthy` on the API service to reduce the startup race window

## [1.0.0] — 2026-03-19

### Added

- `Song` resource with fields: `title`, `artist`, `album`, `genre`, `duration_seconds`, `release_date`, `release_year`, `created_at`
- `Playlist` resource with fields: `name`, `description`, `is_public`, `created_at`, `updated_at`
- Many-to-many `Song`↔`Playlist` relationship via `playlist_songs` association table
- `added_at` timestamp records when each song was linked to a playlist; cascade delete on both foreign keys
- Full CRUD for songs: `GET/POST /songs/` · `GET/PATCH/DELETE /songs/{id}`
- Full CRUD for playlists: `GET/POST /playlists/` · `GET/PATCH/DELETE /playlists/{id}`
- Song–playlist link endpoints: `POST /playlists/{id}/songs/{song_id}` · `DELETE /playlists/{id}/songs/{song_id}`
- Health endpoint: `GET /health`
- Partial update via `PATCH` for both resources — all fields optional
- `PUT` intentionally omitted to prevent accidental data loss
- Omitting `song_ids` on playlist update preserves existing song links
- Providing `song_ids` on update replaces all existing links
- Duplicate `song_ids` deduplicated while preserving input order before any database operation
- `404` with a list of missing IDs returned when any `song_id` in a playlist operation does not exist
- `DATABASE_URL` environment variable with SQLite fallback (`sqlite:///./music.db`) for local development without PostgreSQL
- Database startup retry loop — configurable via `STARTUP_DB_MAX_RETRIES` (default `20`) and `STARTUP_DB_RETRY_SECONDS` (default `2`)
- Eager loading (`selectinload`) on all playlist queries to prevent N+1 patterns

[Unreleased]: https://github.com/renatobueno-dev/music-platform/compare/v1.7.0...HEAD
[1.7.0]: https://github.com/renatobueno-dev/music-platform/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/renatobueno-dev/music-platform/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/renatobueno-dev/music-platform/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/renatobueno-dev/music-platform/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/renatobueno-dev/music-platform/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/renatobueno-dev/music-platform/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/renatobueno-dev/music-platform/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/renatobueno-dev/music-platform/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/renatobueno-dev/music-platform/releases/tag/v1.0.0
