# Development Log — Music Platform API

This document describes **the reasoning and decisions made throughout the process**, following an **incremental, step-by-step approach**, explaining **what was done and why**, including **adjustments, uncertainties, and errors corrected along the way**.

> For consolidated technical reference by topic, see the guides in [`docs/`](./README.md). For API setup and usage, see the [main README](../README.md). For personal process notes and AI workflow, see [DEVELOPMENT_DIARY.md](./DEVELOPMENT_DIARY.md).

---

## 🧩 Initial understanding of the challenge

The project is an **architecture and performance checkpoint**, split into 4 progressive stages:

- **Stage 1** — Functional API with FastAPI + SQLAlchemy
- **Stage 2** — Containerisation with Docker and Compose
- **Stage 3** — Orchestration with Kubernetes and Helm
- **Stage 4** — Production runtime: Istio, Terraform, and CI/CD with GitHub Actions

The chosen domain was a simple music platform: `Song` and `Playlist` with a many-to-many relationship.

The intentional simplicity of the domain was a deliberate decision — it keeps the focus on infrastructure challenges without business complexity competing for attention.

---

## 🗄️ Stage 1 — FastAPI + SQLAlchemy

### Minimal and extensible domain

The starting point was defining the domain before writing any code. That step lives in [`docs/domain/domain-scope.md`](./domain/domain-scope.md).

The decision to include `added_at` in the `playlist_songs` association table was made early: a pure join without metadata loses useful information at no complexity cost. It also serves as a reference point when the model needs to be extended.

### Layer structure

The API was structured in four explicit layers:

```text
routes → schemas → services → models → database
```

The `services/` separation was an important decision: without it, routes would tend to accumulate database logic, and tests would become coupled to HTTP layer details.

### Endpoint plan before implementation

Before writing any routes, [`docs/domain/crud-endpoint-plan.md`](./domain/crud-endpoint-plan.md) was created with the full endpoint map — methods, paths, input/output schemas, and expected status codes.

This prevented the pattern of endpoints growing unintentionally and provided a clear implementation checklist.

### Why `PATCH` and not `PUT`

`SongUpdate` and `PlaylistUpdate` are partial schemas (all fields optional). `PATCH` was the correct choice because the contract is partial update, not full replacement. Using `PUT` with a partial schema would be semantically incorrect.

### Database retry on startup

`main.py` implements a retry loop in `initialize_database()` to handle the case where the database is not yet ready when the API container starts. This was necessary even in development with Docker Compose — `depends_on` with a healthcheck reduces the problem but does not fully eliminate the race window.

The values are configurable via environment:

- `STARTUP_DB_MAX_RETRIES` (default: `20`)
- `STARTUP_DB_RETRY_SECONDS` (default: `2`)

This also simplifies tuning in Kubernetes, where startup behaviour is additionally controlled by Helm probe values.

### `song_ids` behaviour in playlists

`song_ids` in `PlaylistCreate` and `PlaylistUpdate` is optional:

- on create, a playlist can be created empty and songs added later,
- on update, if omitted, existing links are preserved; if provided, they are replaced.

This decision came from thinking through the real usage flow: implicit silent replacement of links would be destructive. The explicit behaviour is documented directly in `README.md`.

---

## 🐳 Stage 2 — Docker and Compose

The full guide is in [`docs/containers/docker-guide.md`](./containers/docker-guide.md).

### Why containerise in stages

The process was intentionally split into five steps (A to E):

- **A (freeze)**: before any Dockerfile, record the values all files must agree on — port, entrypoint, runtime command. Prevents contradictions between Dockerfile, Compose, and documentation.
- **B and C (build + isolated test)**: validate that the image works before introducing the database. When the API breaks, it is easier to diagnose without Compose on top.
- **D (Compose)**: only after the image is validated, add the PostgreSQL dependency.
- **E (log validation)**: confirm the absence of hidden startup errors.

This progression matters because runtime errors surface differently depending on context. An error that goes unnoticed in step B can be much harder to isolate once step D is running.

### `depends_on` with healthcheck

Using `depends_on: condition: service_healthy` was necessary to avoid race conditions. Without the healthcheck, Compose considers the `db` service "ready" as soon as the container starts, not when PostgreSQL is accepting connections. This is a classic mistake that only appears when the database takes slightly longer to start.

---

## ☸️ Stage 3 — Kubernetes and Helm

### Conceptual translation before writing manifests

Before writing any YAML, [`docs/kubernetes/k8s-concept-map.md`](./kubernetes/k8s-concept-map.md) was produced with an explicit translation of every Docker/Compose concept to its Kubernetes equivalent.

The reason: jumping straight to manifests without that map tends to produce YAML that works by trial and error, but without understanding why each resource exists.

### Why StatefulSet for the database

Choosing `StatefulSet` for PostgreSQL instead of `Deployment` came from the need for stable pod identity and persistent storage. A `Deployment` with a PVC works in simple cases, but `StatefulSet` is the correct resource for stateful workloads that require identity — and using the right resource from the start avoids having to migrate later.

### Three-layer probes

The Helm chart includes `startupProbe`, `readinessProbe`, and `livenessProbe` on the same pod, with distinct roles:

- `startupProbe`: gives the API time to initialise without the `livenessProbe` restarting the pod prematurely.
- `readinessProbe`: controls when the pod receives traffic.
- `livenessProbe`: restarts the pod if the process hangs.

The default of `failureThreshold: 30` with `periodSeconds: 2` gives ~65 seconds of warm-up — more than enough for Uvicorn startup plus database connection.

The full chart guide is in [`docs/kubernetes/helm-guide.md`](./kubernetes/helm-guide.md).

---

## 🕸️ Stage 4, Phases 1–3 — Istio

The readiness guide is in [`docs/istio/readiness.md`](./istio/readiness.md).

### Why verify readiness before applying resources

Istio only works if the control plane is healthy and the namespace has `istio-injection=enabled`. Applying a `VirtualService` or `AuthorizationPolicy` before that results in manifests that reach the cluster but have no effect, with no obvious error message.

The readiness checklist was produced to make that prerequisite explicit and verifiable before proceeding.

### Gateway vs VirtualService vs Service

The distinction was important to understand:

- The Kubernetes `Service` handles pod discovery — it knows nothing about HTTP, hosts, or routes.
- The Istio `Gateway` defines the entry point into the mesh.
- The `VirtualService` defines where traffic goes after entering.

Trying to configure host routing directly on the `Service` or `Deployment` is the most common mistake here. The guide in [`docs/istio/traffic.md`](./istio/traffic.md) documents that separation.

### mTLS STRICT and ServiceAccount identity

Enabling `PeerAuthentication` in `STRICT` mode means any non-mTLS communication in the namespace is rejected. This requires dedicated `ServiceAccount` resources for the API and database — `music-platform-api-sa` and `music-platform-db-sa` — so that `AuthorizationPolicy` rules can use principal identity, not just namespace.

The practical consequence: Helm templates had to be updated to reference those accounts. `helm-guide.md` was retroactively updated to include `serviceaccounts.yaml` in the chart structure, fixing an omission that would have been a future conflict point.

The security guide is in [`docs/istio/security.md`](./istio/security.md).

---

## 🏗️ Stage 4, Phase 4 — Terraform

The Terraform scope was defined in four separately documented steps — and that progression was intentional.

The main risk of Terraform in a project that already uses Helm is **dual ownership**: the same Kubernetes object managed by both at the same time. If Terraform creates the namespace and Helm also tries to manage it, `apply` runs start conflicting.

The decision stayed conservative on ownership, but the namespace baseline grew beyond a single label. Terraform now manages the namespace itself, required mesh/platform labels (`istio-injection=enabled` plus Pod Security Standards labels), and namespace guardrails (`ResourceQuota` and `LimitRange`). Everything managed by Helm stays exclusively in Helm.

The guides in [`docs/terraform/`](./terraform/) document this decision in four layers:

- [`scope-and-boundary.md`](./terraform/scope-and-boundary.md): ownership boundary, matrix and minimum locked scope
- [`flow-integration.md`](./terraform/flow-integration.md): Terraform's position in the delivery sequence

---

## ⚙️ Stage 4, Phase 5 — CI/CD with GitHub Actions

The workflow is in `.github/workflows/deploy.yml` and documented in [`docs/cicd/github-actions.md`](./cicd/github-actions.md).

### Deploy guard by secret

The workflow checks whether `KUBE_CONFIG_DATA` is configured before attempting anything that requires cluster access. If the secret is absent, the deploy is skipped with an explicit `::notice::` — instead of failing with an opaque authentication error.

This makes the workflow safe to run in forks or in environments without a configured cluster, without breaking CI.

### Pinned CLI versions

`kubectl`, `helm`, and `terraform` are installed at fixed versions in the workflow. Using `latest` in CI means a silent tool update can break the pipeline without any code change. Pinning versions adds maintenance overhead, but guarantees stability and clear diagnostics when an update is actually needed.

---

## 📚 Documentation: organisation and decisions

Documentation went through two rounds of restructuring.

### First reorganisation: move guides under `docs/`

The `STAGE_*_GUIDE.md` files at the project root were moved to `docs/`. Thirteen flat files at the root make navigation harder and create the impression that important configuration is mixed with reference guides.

### Second reorganisation: topic subdirectories

The 13 guides were reorganised into topic subdirectories:

```text
docs/
├── domain/
├── containers/
├── kubernetes/
├── istio/
├── cicd/
└── terraform/
```

Names were standardised to lowercase-hyphenated, removing the `STAGE_X_` prefixes that organised by implementation order — not by topic.

The reason: stage-based organisation is useful during development, but makes it hard to find a specific guide once the project is complete. A new contributor does not know in which "stage" the mTLS policy was defined — but they know it is in `docs/istio/`.

### Redundancy identified and resolved

A redundancy audit identified four concrete problems:

1. `helm-guide.md` did not list `serviceaccounts.yaml` in the chart structure — the template was added during the Istio security phase but the guide was not updated. A real inconsistency that could cause confusion.
2. `scope.md` (terraform) had an "Initial target set" section that repeated exactly what `min-scope.md` defines more precisely. The section was replaced with a reference.
3. `helm-boundary.md` had a "Practical checkpoint" that re-listed the same scope as `min-scope.md`. Replaced with a reference.
4. `flow-integration.md` had a "Responsibility alignment" section that listed the responsibilities of each layer — already covered exhaustively in the three preceding files. Removed.

The lesson: **redundancy in documentation has the same cost as redundancy in code** — eventually the versions diverge, and when they do, it is not clear which one is correct.

### Third pass: accuracy audit

After the project was complete, a full cross-file audit caught inconsistencies that accumulated through incremental edits:

- The AI workflow table had become inaccurate — two conversations listed instead of the actual five (later corrected to six in a subsequent audit round). Corrected and the working process described.
- Stage 4 phase numbering was reversed in this log: Terraform labelled Phase 5, CI/CD Phase 4. Corrected to the chronological implementation order.
- Test sections in `README.md` and `SETUP_AND_QUALITY.md` documented a planned structure with examples and a priority test table — forward-looking content with no implementation. Simplified to "Under development."
- Alembic migration references updated from aspirational phrasing to "under development."
- CI section link display text in `SETUP_AND_QUALITY.md` corrected to use the filename-only pattern, consistent with all other links in the file.

The lesson: incremental edits accumulate inconsistencies over time. Periodic cross-file audits catch what in-context editing misses.

---

## 🐞 Errors and corrections found along the way

Real problems that surfaced and were fixed:

- **Terraform binary collision in CI** — the `terraform/` directory collided with the binary name during CI installation. Full write-up in [`docs/cicd/github-actions.md`](./cicd/github-actions.md).
- **`serviceaccounts.yaml` missing from helm-guide.md** — the template was created during the Istio security phase but the Helm guide was not updated. Caught in the redundancy audit; corrected.
- **Documentation with inconsistent stage-based naming** — the original guides used `STAGE_X_` prefixes reflecting creation order. Reorganised to reflect topic instead.
- **Four Terraform files repeating the same scope** — the step-by-step progression generated repetition. Redundancy identified and removed with explicit references to `min-scope.md` as the single source of truth.

---

## 🔬 Post-v1.7.0 — Quality, Security, and Audit Work

After the four infrastructure stages were complete and v1.7.0 tagged, a fifth phase focused on quality tooling, static analysis, security, and audit follow-up.

### Static analysis adoption

The static analysis work started from zero: no pylint configuration, no radon baseline. Seven steps were used to reach a clean, stable baseline — documented in [`docs/static-analysis/`](./static-analysis/README.md):

1. Add a `.pylintrc` baseline. Only repository-specific suppressions; no bulk silencing.
2. Fix the real findings surfaced by the default baseline, rather than suppressing them.
3. Add selective docstrings where the default `missing-module-docstring` and `missing-function-docstring` rules trigger on framework-entry-point code that doesn't benefit from them.
4. Narrow suppressions to framework-pattern issues only — `pylint` should still run at full sensitivity on application logic.
5. Reduce radon complexity hotspots. Test helpers were the main complexity sources; they were split into smaller focused functions.
6. Record the CI enforcement decision explicitly: at this stage, pylint and radon stayed local, not in CI yet. This let the baseline stabilise without introducing a new CI gate prematurely.
7. A maintenance policy was documented: the pylint/radon baseline is a floor, not a ceiling. Suppressions are reviewed when adding new code, not accumulated silently.

End state: `pylint 10.00/10`, radon all-A across all rated modules.

### Quality tooling foundation

Before CI was refactored, a repository-wide quality tooling foundation was introduced: Ruff, Prettier, markdownlint, yamllint, shfmt, ShellCheck, actionlint, hadolint, dotenv-linter, a `.editorconfig`, and three helper scripts (`format-all.sh`, `run-quality-tool.sh`, `check-text-hygiene.py`). Pre-commit hooks were added to enforce the same tools locally.

The tool design follows a one-tool-per-responsibility principle — each tool has a clear lane and does not overlap with others:

- Ruff: Python formatting and fast lint.
- Pylint: Python static analysis baseline.
- Radon: Python complexity and maintainability.
- Prettier: Markdown and YAML formatting.
- markdownlint: Markdown structure.
- yamllint: YAML structure (distinct from formatting).
- shfmt + ShellCheck: shell formatting and correctness.
- actionlint: workflow YAML semantic validation.
- hadolint: Dockerfile best practices.
- dotenv-linter: `.env.example` structure.

The full tool stack is described in [`docs/QUALITY.md`](./QUALITY.md).

### Security toolchain rollout

Security was introduced in a staged sequence — four tools first, with a fifth deliberately deferred:

1. **gitleaks**: git-history secret scan. CI runs in `git` mode (full history); local runs scan the current tree.
2. **pip-audit**: checks all pinned dependencies against known vulnerability databases.
3. **lychee**: link checker for documentation, with repo-specific exclusions for localhost and runtime-only URLs.
4. **bandit**: Python security analysis, tuned to application and migration code only — test and helper noise is excluded.
5. **trivy**: container image CVE scanner. Staged for the next phase after initial security gate stability.

The staged approach was deliberate: introducing gitleaks + pip-audit + lychee + bandit together tested the gate under real conditions before adding trivy's larger scan surface.

The security toolchain is described in [`docs/SECURITY_TOOLCHAIN.md`](./SECURITY_TOOLCHAIN.md).

### CI refactoring — four readable jobs

The original CI had one large `validate` job. That job was split into four separate jobs, each with a defined responsibility:

- `fast-quality`: formatting and lint feedback across all file types. Runs first; fails fast on formatting issues.
- `python-quality`: pylint and radon, isolated in their own job so Python quality feedback is never mixed into formatting noise.
- `security-validation`: gitleaks, pip-audit, lychee, bandit — run independently so a security finding doesn't require reading through formatter output.
- `runtime-validation`: contract tests, Docker build, Helm validation, Terraform validation.

All four jobs run in parallel before `deploy`. The separation also makes CI output easier to read: the failure line tells you which category failed.

All jobs were pinned to `ubuntu-24.04` — the same class of decision as pinning CLI versions. Reproducibility requires explicit versions, not moving targets.

### Test suite refactoring

The contract test suite was at ~14 tests at v1.7.0. Radon identified several test helper functions as complexity hotspots — these were functions that combined setup, multiple assertions, and teardown in one body. Each was split into focused, independent test cases.

End state: 46 tests covering all CRUD paths, all 404 paths, all 422 validation paths, relationship endpoints, cascade and empty-list behaviors, and DELETE response standardization.

A related code fix: `DELETE /playlists/{id}/songs/{song_id}` was returning `None` implicitly while `DELETE /songs/{id}` and `DELETE /playlists/{id}` were returning `Response(status_code=204)` explicitly. Standardized all three to the explicit return.

### Supply-chain hardening

Three supply-chain hardening steps were applied:

- **Dockerfile base image SHA-pinned**: `python:3.12-slim@sha256:3d5ed973...`. Tags are mutable — a registry push can silently replace a tag with new layers. The digest is immutable.
- **Helm DB image SHA-pinned**: `postgres:16-alpine@sha256:20edbde7...`. Same rationale; the tag is kept for readability only.
- **Docker Compose DB image SHA-pinned**: same digest as the Helm chart, so the two environments use exactly the same PostgreSQL image.

### External audit and finding resolution

An external documentation and code audit produced 10 findings. All were resolved:

- Startup warm-up time corrected: "~60 seconds" was the wrong arithmetic (it omitted `initialDelaySeconds: 5`). Corrected to "~65 seconds" in this log and in `DEVELOPMENT_DIARY.md`.
- Placeholder list in `docs/fixes/namespace-single-source-of-truth.md` was missing `__ISTIO_TLS_SECRET__`. Added.
- Validation grep commands in two `docs/fixes/` files were missing `__ISTIO_TLS_SECRET__` from the unresolved-placeholder check. Fixed in both.
- `terraform state mv` was the wrong command in `DEVELOPMENT_DIARY.md` — the correct operation is `terraform state rm` when removing a resource from Terraform management. Corrected.
- `docs/fixes/loose-ends-priority-roadmap.md` listed DestinationRule tuning as a pending production-polish item even though Step 6 in the same file recorded it as implemented. Corrected.
- The Related Documents section in the roadmap was missing links to Steps 3–6 and the post-step follow-up file. Added.
- `helm-guide.md` had a hardcoded version tag in the `minikube image load` example command. Replaced with a `<tag>` placeholder with a note to use `values.yaml`.
- `docs/README.md` display text for the troubleshooting link masked the `archive/` path depth. Corrected.

---

## 🏁 Conclusion

The focus of this checkpoint was understanding how a functional API progresses through infrastructure stages without losing control of what each layer does.

The same pattern repeated at every stage:

- understand the concept before applying it,
- map decisions before writing code or YAML,
- validate in small increments,
- and document the reasoning while it is still fresh.

> For technical reference by topic, see the guides in [`docs/`](./README.md).
