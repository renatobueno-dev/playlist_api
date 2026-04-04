# Development Diary — Music Platform API

This document describes **the reasoning and decisions made at the component level throughout the process**, focusing on the **why behind each technical choice** at the layer/component level.

> This is a companion to [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md), which contains the stage-indexed narrative and initial understanding of the challenge. For consolidated technical reference by topic, see the guides in [`docs/`](./README.md).

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

Six conversations with distinct responsibilities:

| Conversation | Model             | Role                                                                                        |
| ------------ | ----------------- | ------------------------------------------------------------------------------------------- |
| 1            | GPT-5.4           | API challenge guidance                                                                      |
| 2            | GPT-5.3-Codex     | Coding                                                                                      |
| 3            | GPT-5.4           | Code explanation and study                                                                  |
| 4            | Claude Sonnet 4.6 | Review, design decisions, and documentation                                                 |
| 5            | Claude Opus 4.6   | Audit — loose ends, structural audit, finding verification                                  |
| 6            | Claude Opus 4.6   | Quality/security rollout guidance, doc gap analysis, finding resolution, documentation sync |

**How I worked:** Read all guidance first, then asked Codex to execute each step. Even after understanding what was done, I sent the output to a separate GPT conversation for explanation. Followed that logic end to end through the full challenge. When the challenge was complete, switched to Sonnet for documentation only and Opus for auditing only. Any new guidance or coding goes back to the GPT workflow to keep consistency and sources of truth.

---

## 🗄️ Domain: data model and relationship decisions

### Why `added_at` in the association table

The initial instinct was a pure join table — just `playlist_id` and `song_id`. That would have worked. But adding `added_at` (datetime, auto-generated) costs nothing at the schema level and permanently records when each song entered a playlist.

A pure join without metadata destroys that information irreversibly. Adding it later would require a schema migration and would lose historical data for all existing links. Including it at the start was the safer decision.

### Domain scope before any code

Before writing models, the full domain was documented in [`docs/domain/domain-scope.md`](./domain/domain-scope.md). The value of doing this first is that it forces explicit decisions about field types, optional vs required, and relationships — before runtime behaviour makes them harder to change.

The fields that ended up in the final model (`release_year` alongside `release_date`, `duration_seconds` as optional) came out of that planning step, not from refactoring an initial draft.

---

## 📦 Schemas: request and response contracts

### `SongUpdate` and `PlaylistUpdate` as partial schemas

`SongUpdate` and `PlaylistUpdate` have all fields optional. This means `PATCH` is the correct HTTP method — the contract is explicitly partial update, not full replacement.

Using `PUT` with an all-optional schema would be semantically wrong. `PUT` promises a full replacement of the resource. If every field is optional, nothing guarantees the resource ends up in a well-defined state after the call.

### `song_ids` behaviour in playlist operations

`song_ids` in `PlaylistCreate` and `PlaylistUpdate` is optional:

- on create: a playlist can be created empty and songs added later via relationship endpoints.
- on update: **if omitted, existing links are preserved**; if provided, they are fully replaced.

The replace-on-update behaviour was a deliberate design decision. Silent accumulation of links on every `PATCH` would be harder to reason about and harder to test. Explicit replacement is easier to predict and document.

This behaviour is called out in `README.md` directly — not just in internal guides — because it is the kind of decision that surprises API callers.

---

## 🔁 Services: why the layer exists

The `services/` layer (`song_service.py`, `playlist_service.py`) separates database logic from HTTP handling.

Without it, routes accumulate queries, ORM calls, and business logic. The progressive creep happens quickly: first it is a small query inline, then it gets an `if` condition, then another filter. The result is routes that are hard to test without the full HTTP stack and business logic that cannot be reused.

Separating services from the start meant:

- routes handle only HTTP concerns (status codes, request/response shape),
- services handle database interaction and business rules,
- tests can reach service functions directly without spinning up an HTTP client.

The layer structure is documented as `routes → schemas → services → models → database` and was established before any routes were written.

---

## 📡 Routes: endpoint decisions

### Endpoint map before implementation

Before writing any routes, [`docs/domain/crud-endpoint-plan.md`](./domain/crud-endpoint-plan.md) was produced with the full endpoint map: methods, paths, input/output schemas, expected status codes. This served as a checklist and prevented routes from growing unintentionally.

### 404 vs silent return

Non-existent IDs return `404`. This is explicit because the alternative — returning an empty result or `200` with no body — is a common shortcut that misleads callers into thinking a resource was found.

A `404` makes the contract clear: the resource either exists and is accessible, or it does not exist. Callers can distinguish "the resource is empty" from "the resource was not found."

### Relationship endpoints as a later addition

`POST /playlists/{id}/songs/{song_id}` and `DELETE /playlists/{id}/songs/{song_id}` were added as a separate step after the core CRUD was working. The relationship between songs and playlists requires both resources to exist and be individually validated. Adding this after core CRUD meant validation logic for both sides was already in place and tested.

---

## 🐳 Docker and Compose: containerisation in stages

### The five-step progression (A to E)

The containerisation process was split intentionally:

- **A (freeze)**: before writing a Dockerfile, record the values all files must agree on — port, entrypoint, runtime command. If these are not locked first, contradictions between Dockerfile, Compose, and documentation appear silently.
- **B and C (build + isolated test)**: validate the API image independently, without the database. When the API breaks, the cause is simpler to isolate without Compose complexity on top.
- **D (Compose)**: only after the image is validated, add the PostgreSQL dependency.
- **E (log validation)**: confirm the absence of hidden startup errors, import problems, and DB connection issues.

The full guide is at [`docs/containers/docker-guide.md`](./containers/docker-guide.md).

### `depends_on` with healthcheck

Using `depends_on: condition: service_healthy` was necessary to avoid startup race conditions. Without the healthcheck condition, Compose considers `db` ready when the container starts — not when PostgreSQL is actually accepting connections. This caused real connection failures during development when the database took slightly longer to initialise.

---

## ☸️ Kubernetes and Helm: orchestration decisions

### Concept map before writing manifests

Before writing any YAML, [`docs/kubernetes/k8s-concept-map.md`](./kubernetes/k8s-concept-map.md) was produced with an explicit translation of every Docker/Compose concept to its Kubernetes equivalent.

Jumping directly to manifests without that map tends to produce YAML that works by trial and error — but without clear understanding of why each resource exists. Writing the map first forced explicit decisions about `Deployment` vs `StatefulSet`, how `ConfigMap` and `Secret` relate to env vars, and where `depends_on` behaviour goes in Kubernetes (probes and retries, not startup ordering).

### Why `StatefulSet` for the database

`Deployment` with a PVC works for simple cases, but `StatefulSet` is the correct resource for stateful workloads requiring stable identity and persistent storage. Using the right resource from the start avoids a later migration — which is disruptive because it involves pod naming and storage binding changes.

### Three-layer probes

The Helm chart uses `startupProbe`, `readinessProbe`, and `livenessProbe` with distinct roles:

- `startupProbe`: allows warm-up time before `livenessProbe` starts enforcing. Without it, a slow-starting container gets restarted before it has a chance to reach healthy status.
- `readinessProbe`: controls when the pod receives traffic — decoupled from whether it is alive.
- `livenessProbe`: restarts a hung process.

The default `failureThreshold: 30` with `periodSeconds: 2` gives ~65 seconds of warm-up — enough for Uvicorn startup plus database connection in a slow environment.

---

## 🕸️ Istio: mesh configuration decisions

### Readiness check before applying resources

Istio only works if the control plane is healthy and the namespace has `istio-injection=enabled`. Applying a `VirtualService` or `AuthorizationPolicy` before that results in manifests accepted by the cluster with no visible effect and no useful error. The readiness checklist in [`docs/istio/readiness.md`](./istio/readiness.md) makes that prerequisite explicit and verifiable before proceeding.

### Gateway vs VirtualService vs Kubernetes Service

The three-way distinction was one of the more confusing parts of Istio:

- The Kubernetes `Service` handles pod discovery — it knows nothing about HTTP hosts or routing rules.
- The Istio `Gateway` defines the external entry point into the mesh (which hostname, which port).
- The `VirtualService` defines where traffic goes once it enters the mesh.

The most common mistake here is trying to configure host-based routing directly on the `Service` or `Deployment`. That concept does not exist at the Kubernetes layer. The guide in [`docs/istio/traffic.md`](./istio/traffic.md) documents this separation explicitly to avoid that confusion later.

### mTLS STRICT and ServiceAccount identity

Enabling `PeerAuthentication` in `STRICT` mode means non-mTLS traffic in the namespace is rejected entirely. This required creating dedicated `ServiceAccount` resources for the API (`music-platform-api-sa`) and database (`music-platform-db-sa`) — without them, `AuthorizationPolicy` rules cannot target workloads by principal identity.

The practical consequence: Helm templates had to be updated to reference those accounts in `api-deployment.yaml`, `db-statefulset.yaml`, and `serviceaccounts.yaml`. The Helm guide was also retroactively updated to include `serviceaccounts.yaml` in the chart structure — an omission caught during the redundancy audit.

---

## 🏗️ Terraform: infrastructure-as-code scope

### The dual-ownership problem

The main risk of Terraform in a project that already uses Helm is managing the same Kubernetes object from both. If Terraform creates a namespace and Helm's `--create-namespace` also manages it, they conflict silently on `apply`.

The decision stayed conservative on ownership: Terraform manages the `music-platform` namespace baseline, which now includes required mesh/platform labels (`istio-injection=enabled` plus Pod Security Standards labels) and namespace guardrails (`ResourceQuota` and `LimitRange`). Everything generated by Helm stays exclusively in Helm. This boundary is the core of the Terraform documentation.

### Conservative minimum scope

The minimum scope was chosen not because it is the most interesting thing Terraform can do, but because it is the safest thing it can do that adds real value:

- It is infrastructure-level, not application-release-level.
- It is a direct prerequisite for Helm deploy and Istio behaviour.
- It has no overlap with any Helm-managed object.

Expanding from a safe minimum is straightforward. Contracting from an overly broad Terraform scope that conflicts with Helm requires `terraform state rm` and migration coordination.

### Four documentation layers for a single decision

The Terraform documentation was originally split into four files — `scope.md`, `helm-boundary.md`, `min-scope.md`, `flow-integration.md` — because the scope decision has four distinct aspects:

1. What Terraform owns (vs what it does not).
2. How the boundary with Helm is defined operationally.
3. What the minimum locked scope is for this project.
4. Where Terraform fits in the delivery sequence.

Merging these into one file would create a document where "what is the namespace" and "how does Terraform fit in CI/CD" compete for attention. The four files were later consolidated into two — `scope-and-boundary.md` (aspects 1–3) and `flow-integration.md` (aspect 4) — which preserves this separation while reducing file count.

---

## ⚙️ CI/CD: GitHub Actions pipeline

### Deploy guard by secret

The workflow checks whether `KUBE_CONFIG_DATA` is configured before attempting anything that requires cluster access. If the secret is absent, the deploy steps are skipped with `::notice::` rather than failing with an opaque authentication error.

This matters in practice: the repository might be forked, run in an environment without cluster access, or used by a contributor who should not be deploying. Failing loudly with an auth error sends the wrong signal. An explicit notice sends the right one.

### Pinned CLI versions

`kubectl`, `helm`, and `terraform` are installed at fixed versions. Using `latest` in CI means a tool update can break the pipeline without any code change and without any useful error message pointing to the tool version as the cause.

Pinned versions add a maintenance task when a new version is actually needed — but eliminate one class of silent failures and make troubleshooting deterministic.

### Terraform binary collision

The project has a `terraform/` directory at the root. The default Terraform install extracts the binary into the working directory — creating a filename collision with that directory. This caused a cryptic `error: cannot delete old terraform / Is a directory` failure during CI development.

The fix is to extract into a temporary directory, then move the binary to `/usr/local/bin`. The story is documented in [`docs/cicd/github-actions.md`](./cicd/github-actions.md) as a known troubleshooting case.

---

## 📚 Documentation: organisation and decisions

### Stage-based naming vs topic-based organisation

The initial guides used `STAGE_X_` prefixes that organised by implementation order. That worked during development. Once the project was complete, it stopped working for reference: a contributor looking for the mTLS policy does not know which "stage" contains it — they only know it is an Istio concept.

The guides were reorganised into topic subdirectories (`domain/`, `containers/`, `kubernetes/`, `istio/`, `cicd/`, `terraform/`) with lowercase-hyphenated names. Topic-based organisation serves the completed project; stage-based organisation served the development process.

### Redundancy identified and resolved

A redundancy audit identified four concrete inconsistencies:

1. `helm-guide.md` did not list `serviceaccounts.yaml` — the template was added during the Istio phase and the Helm guide was not updated. A real inconsistency that would cause confusion for anyone building from the guide.
2. `terraform/scope.md` had a section that repeated what `min-scope.md` defines more precisely — replaced with a reference.
3. `terraform/helm-boundary.md` had a section re-listing the same scope — replaced with a reference.
4. `terraform/flow-integration.md` had a "responsibility alignment" section already covered exhaustively in the three preceding files — removed.

These four files were later consolidated into two: `scope-and-boundary.md` and `flow-integration.md`.

**The lesson: redundancy in documentation has the same cost as redundancy in code** — eventually the versions diverge, and when they do, it is not clear which one is correct.

### Accuracy audit after the fact

After the project was complete, a full cross-file audit caught five inconsistencies that had accumulated through incremental edits:

- The AI workflow table listed two conversations instead of five (later corrected to six in a subsequent audit round). Corrected.
- Stage 4 phase numbering was reversed in `DEVELOPMENT_LOG.md` (Terraform labelled Phase 5, CI/CD Phase 4 — reversed from the actual implementation order). Corrected.
- Test sections in `README.md` and `SETUP_AND_QUALITY.md` (since split into `SETUP.md` and `QUALITY.md`) described planned content with no implementation. Simplified to "Under development."
- Alembic migration references updated from aspirational phrasing to "under development."
- CI section link display text corrected to the filename-only pattern used consistently elsewhere.

Periodic cross-file audits catch what in-context editing misses. The cost of skipping them is documentation that contradicts itself.

---

## 🐞 Real errors and corrections

Problems that surfaced during the process and required explicit fixes:

- **`serviceaccounts.yaml` missing from `helm-guide.md`** — the template was created during the Istio security phase and the Helm guide was not updated. Caught in redundancy audit and corrected.
- **Stage-based doc naming** — the `STAGE_X_` prefix system made reference navigation harder once the project was complete. Reorganised to topic-based structure.
- **Duplicate Terraform scope content** — four files created incrementally produced three sections repeating the same scope boundary. Consolidated with references to `min-scope.md` as the single source of truth. Later merged from four files into two (`scope-and-boundary.md` and `flow-integration.md`).
- **Documentation with forward-looking content** — test coverage and migration tracking sections described intended future state as if already implemented. Simplified to "under development."

---

## 🔬 Quality and analysis layer decisions

### Why Ruff does not replace Pylint or Radon

Ruff, Pylint, and Radon each have a distinct role — this is not redundancy:

- **Ruff** is a fast formatter and lint layer. It catches style issues, import ordering, and many common code smells in milliseconds. It runs in the `fast-quality` CI job, before anything else.
- **Pylint** is the static analysis baseline. It runs deeper analysis — unused arguments, unreachable code, interface misuse, and framework-specific patterns — and reports at a score level, not just pass/fail.
- **Radon** measures complexity and maintainability independently. A file can pass Pylint at 10.00/10 and still have a function with cyclomatic complexity C or maintainability index B. Radon surfaces that separately.

The boundary is: if Ruff can catch it cheaply, Ruff catches it. If it requires deeper analysis, Pylint or Radon catches it. No overlap, no gaps.

### Why security tools were staged

Four tools were introduced together (`gitleaks`, `pip-audit`, `lychee`, `bandit`); a fifth (`trivy`) was deliberately deferred.

The reason is gate stability. Introducing multiple security tools at once means any initial false positive or configuration gap has to be triaged across all of them simultaneously. Starting with four tools that have clear tuning dials (bandit's confidence/severity thresholds, lychee's exclusion list, pip-audit's known-safe list) let the gate reach a stable state before adding trivy's container CVE scanner, which requires a separate image-pull infrastructure in CI.

The full staging rationale is in [`docs/SECURITY_TOOLCHAIN.md`](./SECURITY_TOOLCHAIN.md).

### Why contract tests were split into smaller focused cases

Radon flagged several test helper functions as the main complexity hotspots. These were functions that combined fixture setup, multiple endpoint calls, and several assertions into one body — the kind of helper that starts as a convenience and grows over time.

Splitting them into focused, independent test cases brought complexity down while making each test more readable: a failing test now names exactly what contract was violated, rather than producing a long traceback from inside a shared helper.

End state: 46 focused test cases from the original ~14.

### Why CI was split into four jobs

The original single `validate` job produced a monolithic output blob that mixed Python formatting errors, security findings, container validation failures, and test results. A formatting failure required reading through the entire job log to find it.

Four jobs with explicit responsibilities — `fast-quality`, `python-quality`, `security-validation`, `runtime-validation` — give precise failure signals. The job name tells you the category before you open the output. They also run in parallel, so the end-to-end CI time does not increase with the job count.

### Why SHA-pinning was applied

Container image tags are mutable. A `docker pull python:3.12-slim` at different times can return different image layers if the maintainer has pushed an update. In a CI/CD pipeline, this means a build that passed yesterday can fail today without any code change, and the error points to the application code rather than the registry.

Digest pinning (`@sha256:...`) makes the image reference immutable — the build always uses exactly the same layers. The tag is kept alongside the digest for human readability only; the digest is the actual constraint. Three images were pinned: API base image (Dockerfile), DB image (Helm values.yaml), and DB image (docker-compose.yml). Keeping the same digest in both Helm and Compose ensures the PostgreSQL version is identical across local and cluster environments.

### Why DELETE handlers were standardized to explicit `Response(status_code=204)`

`DELETE /playlists/{id}/songs/{song_id}` was returning `None` implicitly — FastAPI infers a 204 response when the return type is `None` and the route is decorated with `status_code=204`. The other two delete routes returned `Response(status_code=204)` explicitly.

Both forms work. But the implicit form hides the intent: a reader must know how FastAPI handles `-> None` on a 204 route to confirm the behavior. The explicit form makes the contract visible without needing to know the framework convention. Consistency across the three routes removes one class of reader confusion.

---

## 🏁 Conclusion

The infrastructure progression in this project follows the same pattern at every layer:

- understand the concept before writing the resource,
- map responsibilities before creating files or manifests,
- validate in small increments,
- and record the reasoning while it is still fresh.

The complexity in a project like this is not in any individual component — it is in how the layers interact. Kubernetes depends on Docker; Istio depends on Kubernetes; Terraform ensures the prerequisites; GitHub Actions orchestrates all of them. Losing track of that ordering once is enough to spend hours on an error that has nothing to do with the broken component.

> For consolidated technical reference by topic, see the guides in [`docs/`](./README.md). For the authoritative stage narrative, see [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md).

---

## 🔗 Related documents

- [Development Log](./DEVELOPMENT_LOG.md)
- [Architecture decisions](./ARCHITECTURE.md)
- [Documentation index](./README.md)
