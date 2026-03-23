# Development Log — Music Platform API

This document describes **the reasoning and decisions made throughout the process**, following an **incremental, step-by-step approach**, explaining **what was done and why**, including **adjustments, uncertainties, and errors corrected along the way**.

> For consolidated technical reference by topic, see the guides in [`docs/`](./README.md). For API setup and usage, see the [main README](../README.md).

---

## 🤖 How AI was used in this project

Most of the code and architecture decisions were produced with AI assistance.

My active role throughout the process was:
- reading and understanding each generated part,
- questioning decisions that were not clear,
- redirecting when the output did not reflect the original intent,
- and consciously choosing what to keep, adapt, or discard.

The deliberate focus of this checkpoint was **deployment architecture** — understanding how a simple API progresses through infrastructure stages: from running locally to a full pipeline with Kubernetes, Istio, Terraform, and CI/CD.

### AI workflow

Five conversations with distinct responsibilities:

| Conversation | Model | Role |
|---|---|---|
| 1 | GPT-5.4 | API challenge guidance |
| 2 | GPT-5.3-Codex | Coding |
| 3 | GPT-5.4 | Code explanation and study |
| 4 | Claude Sonnet 4.6 | Review, design decisions, and documentation |
| 5 | Claude Opus 4.6 | Audit — looking for loose ends |

**How I worked:** Read all guidance first, then asked Codex to execute each step. Even after understanding what was done, I sent the output to a separate GPT conversation for explanation. Followed that logic end to end through the full challenge. When the challenge was complete, switched to Sonnet for documentation only and Opus for auditing only. Any new guidance or coding goes back to the GPT workflow to keep consistency and sources of truth.

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

```
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

The default of `failureThreshold: 30` with `periodSeconds: 2` gives ~60 seconds of warm-up — more than enough for Uvicorn startup plus database connection.

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

The decision was simple and conservative: Terraform manages only the namespace and platform labels (specifically `istio-injection=enabled`). Everything managed by Helm stays exclusively in Helm.

The guides in [`docs/terraform/`](./terraform/) document this decision in four layers:
- [`scope.md`](./terraform/scope.md): initial ownership boundary
- [`helm-boundary.md`](./terraform/helm-boundary.md): Terraform × Helm × GitHub Actions ownership matrix
- [`min-scope.md`](./terraform/min-scope.md): minimum scope locked for delivery
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

```
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

- The AI workflow table had become inaccurate — two conversations listed instead of the actual five. Corrected and the working process described.
- Stage 4 phase numbering was reversed in this log: Terraform labelled Phase 5, CI/CD Phase 4. Corrected to the chronological implementation order.
- Test sections in `README.md` and `SETUP_AND_QUALITY.md` documented a planned structure with examples and a priority test table — forward-looking content with no implementation. Simplified to "Under development."
- Alembic migration references updated from aspirational phrasing to "under development."
- CI section link display text in `SETUP_AND_QUALITY.md` corrected to use the filename-only pattern, consistent with all other links in the file.

The lesson: incremental edits accumulate inconsistencies over time. Periodic cross-file audits catch what in-context editing misses.

---

## 🐞 Errors and corrections found along the way

Real problems that surfaced and were fixed:

- **Terraform binary collision in CI** — the `terraform/` directory at the project root conflicted with the Terraform binary name during workflow installation. The install script tried to unzip the binary directly into the workspace, causing a name collision (`error: cannot delete old terraform / Is a directory`). Fixed by extracting the zip into a temporary directory and moving the binary to `/usr/local/bin`.
- **`serviceaccounts.yaml` missing from helm-guide.md** — the template was created during the Istio security phase but the Helm guide was not updated. Caught in the redundancy audit; corrected.
- **Documentation with inconsistent stage-based naming** — the original guides used `STAGE_X_` prefixes reflecting creation order. Reorganised to reflect topic instead.
- **Four Terraform files repeating the same scope** — the step-by-step progression generated repetition. Redundancy identified and removed with explicit references to `min-scope.md` as the single source of truth.

---

## 🏁 Conclusion

The focus of this checkpoint was understanding how a functional API progresses through infrastructure stages without losing control of what each layer does.

The same pattern repeated at every stage:
- understand the concept before applying it,
- map decisions before writing code or YAML,
- validate in small increments,
- and document the reasoning while it is still fresh.

> For technical reference by topic, see the guides in [`docs/`](./README.md).
