# Documentation

> Topic-based reference for the Music Platform API. Each guide covers one area of the stack independently — navigate by topic below.

## 📋 Project-wide guides

| File | Description |
| --- | --- |
| [CHANGELOG.md](../CHANGELOG.md) | Notable changes per version — Added, Changed, Fixed |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Data model, layer structure, and application-level design decisions |
| [INFRA_DECISIONS.md](./INFRA_DECISIONS.md) | Kubernetes, Istio, Terraform, and CI/CD design decisions |
| [SETUP.md](./SETUP.md) | Environment variables and local/Docker/Kubernetes setup |
| [SECRETS_OWNERSHIP.md](./SECRETS_OWNERSHIP.md) | Secret ownership boundary: origin, injection, rotation, and allowed definers by environment |
| [MIGRATIONS.md](./MIGRATIONS.md) | Migration lifecycle source of truth: ownership, baseline, and environment workflow differences |
| [LIFECYCLE_VALIDATION.md](./LIFECYCLE_VALIDATION.md) | Final lifecycle validation summary across local, tests, Docker, Kubernetes, and Istio ingress |
| [QUALITY.md](./QUALITY.md) | Testing guide and CI overview |
| [API.md](./API.md) | Stable API endpoint reference with schemas and status codes |
| [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md) | Development journey — reasoning, decisions, and corrections per stage |
| [DEVELOPMENT_DIARY.md](./DEVELOPMENT_DIARY.md) | Component-level decisions and reasoning — the why behind each technical choice |
| [DEVELOPMENT_LOG_RESTART.md](./archive/DEVELOPMENT_LOG_RESTART.md) | Historical log of the unpushed commit execution window before guidance restart |
| [DEVELOPMENT_DIARY_RESTART.md](./archive/DEVELOPMENT_DIARY_RESTART.md) | Restart rationale, execution reset context, and guardrails for the next cycle |

## 🎵 Domain

| File | Description |
| --- | --- |
| [domain-scope.md](./domain/domain-scope.md) | Domain model fields and relationship decisions for `Song` and `Playlist` |
| [crud-endpoint-plan.md](./domain/crud-endpoint-plan.md) | CRUD route planning artifact — methods, schemas, status codes, and implementation order |

## 🐳 Containers

| File | Description |
| --- | --- |
| [docker-guide.md](./containers/docker-guide.md) | Docker image build and validation — Steps A–C |
| [compose-guide.md](./containers/compose-guide.md) | Docker Compose multi-service stack — Steps D–E |

## ☸️ Kubernetes

| File | Description |
| --- | --- |
| [k8s-concept-map.md](./kubernetes/k8s-concept-map.md) | Docker/Compose → Kubernetes resource concept translation |
| [helm-guide.md](./kubernetes/helm-guide.md) | Helm chart structure, values, and install/lint commands |

## 🕸️ Istio

| File | Description |
| --- | --- |
| [readiness.md](./istio/readiness.md) | Istio readiness checklist and pre-install validation |
| [traffic.md](./istio/traffic.md) | Gateway, VirtualService, and DestinationRule resilience configuration |
| [security.md](./istio/security.md) | mTLS PeerAuthentication and AuthorizationPolicy rules |

## 🔄 CI/CD

| File | Description |
| --- | --- |
| [github-actions.md](./cicd/github-actions.md) | GitHub Actions workflow: triggers, build/push, and deploy steps |

## 🏗️ Terraform

| File | Description |
| --- | --- |
| [scope-and-boundary.md](./terraform/scope-and-boundary.md) | Terraform ownership boundary, Helm separation matrix, and minimum locked scope |
| [flow-integration.md](./terraform/flow-integration.md) | Integrating Terraform into the full Helm/Istio/CI pipeline |
| [state-management-policy.md](./terraform/state-management-policy.md) | Terraform state usage policy: single-user vs shared execution, locking expectations, and recovery thinking |

## 🧭 Roadmap

| File | Description |
| --- | --- |
| [roadmap/README.md](./roadmap/README.md) | Roadmap implementation index and phase-folder conventions |
| [step-1-minimum-test-scope.md](./roadmap/phase-1/step-1-minimum-test-scope.md) | Phase 1 Step 1 boundary for the first minimum API contract test surface |
| [step-2-first-test-layer.md](./roadmap/phase-1/step-2-first-test-layer.md) | Phase 1 Step 2 decision that API contract behavior is the first testing layer |
| [step-3-clean-test-environment.md](./roadmap/phase-1/step-3-clean-test-environment.md) | Phase 1 Step 3 setup for repeatable, isolated, and disposable local test execution |
| [step-4-smallest-green-slice.md](./roadmap/phase-1/step-4-smallest-green-slice.md) | Phase 1 Step 4 validation of root and health endpoints as the first green test slice |
| [step-5-songs-crud-tests.md](./roadmap/phase-1/step-5-songs-crud-tests.md) | Phase 1 Step 5 songs CRUD contract coverage with missing-id and invalid-payload behavior |
| [step-6-playlists-crud-tests.md](./roadmap/phase-1/step-6-playlists-crud-tests.md) | Phase 1 Step 6 playlists CRUD contract coverage with partial update, missing-id, and invalid-payload behavior |
| [step-7-playlist-song-relationship-tests.md](./roadmap/phase-1/step-7-playlist-song-relationship-tests.md) | Phase 1 Step 7 many-to-many relationship coverage for link/unlink, replacement, and conflict handling |
| [step-8-negative-tests.md](./roadmap/phase-1/step-8-negative-tests.md) | Phase 1 Step 8 focused negative-path coverage for invalid payloads, missing resources, and invalid relationship identifiers |
| [step-9-local-test-stability.md](./roadmap/phase-1/step-9-local-test-stability.md) | Phase 1 Step 9 local repeatability baseline with clean-state multi-run verification |
| [step-10-ci-test-integration.md](./roadmap/phase-1/step-10-ci-test-integration.md) | Phase 1 Step 10 CI validation extension to execute API contract tests on pull requests |
| [step-11-migration-ownership.md](./roadmap/phase-2/step-11-migration-ownership.md) | Phase 2 Step 11 migration ownership definition before introducing Alembic tooling |
| [step-12-baseline-migration-strategy.md](./roadmap/phase-2/step-12-baseline-migration-strategy.md) | Phase 2 Step 12 baseline strategy defining the first tracked schema state and rollout path |
| [step-13-migration-structure.md](./roadmap/phase-2/step-13-migration-structure.md) | Phase 2 Step 13 Alembic framework structure introduction and migration home setup |
| [step-14-clean-db-upgrade-validation.md](./roadmap/phase-2/step-14-clean-db-upgrade-validation.md) | Phase 2 Step 14 proof that a clean database can be rebuilt through migration upgrade flow |
| [step-15-reduce-create-all-responsibility.md](./roadmap/phase-2/step-15-reduce-create-all-responsibility.md) | Phase 2 Step 15 removal of startup `create_all` authority in favor of migration-first schema evolution |
| [step-16-document-migration-workflow.md](./roadmap/phase-2/step-16-document-migration-workflow.md) | Phase 2 Step 16 stable migration workflow documentation and environment-flow clarification |
| [step-17-secret-ownership-boundary.md](./roadmap/phase-3/step-17-secret-ownership-boundary.md) | Phase 3 Step 17 secret ownership boundary definition across local, cluster, and CI delivery paths |
| [step-18-secret-flow-alignment.md](./roadmap/phase-3/step-18-secret-flow-alignment.md) | Phase 3 Step 18 deployment-flow alignment across Terraform baseline, CI orchestration, and Helm runtime secret consumption |
| [step-19-state-management-policy.md](./roadmap/phase-4/step-19-state-management-policy.md) | Phase 4 Step 19 Terraform state-management policy for collaboration expectations, locking discipline, and recovery guidance |
| [step-20-platform-guardrails-expansion.md](./roadmap/phase-5/step-20-platform-guardrails-expansion.md) | Phase 5 Step 20 namespace/platform guardrail expansion with Terraform-managed `ResourceQuota` and `LimitRange` baseline |

## 🔧 Post-checkpoint fixes

| File | Description |
| --- | --- |
| [fixes/README.md](./fixes/README.md) | Index and overview of all post-checkpoint remediation work |

## 🔍 Troubleshooting

| File | Description |
| --- | --- |
| [troubleshooting/errors-session-register.md](./archive/troubleshooting/errors-session-register.md) | Session-scoped error register — observed CI, Terraform, and local tooling errors with root-cause groups |
