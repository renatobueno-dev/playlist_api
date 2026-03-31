# Loose Ends Priority Roadmap

> Historical remediation record for confirmed repository loose ends. Each step below links to a dedicated implementation file with problem, goal, and validation details.

---

## 📝 Context

Repository audit confirms real implementation loose ends in code and infrastructure.
Current documentation quality is strong, so the next cycle focuses on practical remediation with explicit priorities.

Stage 4 checkpoint emphasis is:

- Istio traffic management
- security policies
- GitHub Actions deployment automation

Terraform is part of the toolset, but not a standalone mission bullet in Stage 4.
This distinction guides what is checkpoint-priority versus production-polish.

## 🔍 Confirmed Loose Ends

This section captures the baseline audit snapshot before remediation steps were executed.
Implementation status per step is tracked below in the ordered remediation section.

- `helm/music-platform/values.yaml`
  - API image still defaults to `tag: "latest"`.
  - `api.resources` and `db.resources` are empty.
  - DB image still uses loose `postgres:16-alpine`.
  - `db.password` defaults to `postgres`.
- `helm/music-platform/templates/secret.yaml`
  - Secret material is directly derived from chart values through `stringData`.
- `.github/workflows/deploy.yml`
  - Uses floating action versions (`actions/checkout@v5`, others).
  - Applies Istio manifests without explicit namespace scoping in apply commands.
  - No concurrency guard for deploy race prevention.
- `Dockerfile`
  - Missing non-root `USER`.
  - Missing `HEALTHCHECK`.
- `requirements.txt`
  - Dependencies are unpinned.
- `app/database.py`
  - `DATABASE_URL` silently falls back to SQLite.
- `.env.example`
  - Contains only basic DB/API variables.
- `terraform/versions.tf` and namespace model
  - Provider constraint is `~> 2.36`.
  - Baseline labels guarantee only `istio-injection=enabled`.
- `k8s/istio/traffic-management.yaml` and `k8s/istio/security-policies.yaml`
  - Both hardcode `namespace: music-platform`.
  - Traffic file has no `DestinationRule`.

## 📊 Priority Model

### Checkpoint-priority

1. Namespace consistency across Terraform, workflow, and Istio manifests.
2. Security defaults in Helm (`db.password`, image tag, secret handling).
3. Runtime hardening baseline (`USER`, `HEALTHCHECK`, resources, DB config posture).
4. CI reproducibility (pinned dependencies, pinned images, workflow determinism).
5. Terraform posture consistency and explicit ownership.

### Production-polish

1. DestinationRule resilience tuning.
2. External secret manager adoption.
3. Remote backend and locking expansion for Terraform.
4. Stricter provider pin granularity.
5. Additional namespace security posture expansion.

## 📍 Ordered Remediation Steps

## 📦 Step 1 - Namespace Single Source of Truth

Status:

- Implemented.

Why first:

- It removes drift between Terraform namespace ownership, workflow `NAMESPACE`, and Istio manifest namespaces.
- It unblocks safe namespace changes later without hidden breakage.

Goal:

- Keep namespace ownership coherent across Terraform, Helm/workflow, and Istio apply flow.

## 🔐 Step 2 - Security Defaults Hardening

Status:

- Implemented.

Why second:

- Weak defaults are highly visible in review and directly affect security posture.

Goal:

- Remove demo-grade defaults and make chart behavior intentional:
  - avoid plaintext DB password defaults,
  - avoid `latest` as baseline image tag,
  - improve secret value ownership strategy.

## 👊 Step 3 - Runtime Hardening Baseline

Status:

- Implemented.

Why third:

- After configuration consistency and secure defaults, hardening the runtime closes obvious operational gaps.

Goal:

- Reduce the "works but weakly hardened" profile:
  - non-root container user,
  - healthcheck in image,
  - resource requests/limits defaults,
  - explicit DB runtime configuration policy.

## 🔄 Step 4 - Pipeline Reproducibility

Status:

- Implemented.

Why fourth:

- High value for repeatability, lower urgency than Steps 1-3 for checkpoint correctness.

Goal:

- Make pipeline runs deterministic:
  - action pinning strategy,
  - Python dependency pinning,
  - container image pinning where possible,
  - workflow concurrency protection.

## 🏗️ Step 5 - Terraform/Kubernetes Posture

Status:

- Implemented.

Why fifth:

- Strengthens infrastructure quality after core checkpoint-critical remediations.

Goal:

- Make Terraform look intentional infrastructure code:
  - tighter provider policy,
  - clearer namespace posture baseline,
  - explicit backend and locking strategy.

## ✨ Step 6 - Istio Resilience Polish (DestinationRule)

Status:

- Implemented.

Why last:

- Important hardening, but not the first blocker for Stage 4 delivery requirements.

Goal:

- Move from "Istio present and secure" to "Istio secure and more resilient."

## 🔧 Post-Step Follow-ups

Status:

- Implemented.

Scope:

- Terraform provider constraint refined to patch-level (`~> 2.38.0`).
- Startup DB retry environment variables documented in `.env.example`.

## 🧾 Historical Execution Sequence

The sequence below reflects how remediation was executed (already completed), not a pending task queue.

Execution order used:

1. Step 1 - Namespace consistency
2. Step 2 - Security defaults
3. Step 3 - Runtime hardening
4. Step 4 - Pipeline reproducibility
5. Step 5 - Terraform posture
6. Step 6 - DestinationRule and resilience tuning

Optional production extras (not required for Stage 4 mission scope) remain separate:

1. External secrets manager adoption
2. Advanced Terraform backend/locking patterns

---

## 🔗 Related documents

- [Fixes index](./README.md)
- [Namespace single source of truth](./namespace-single-source-of-truth.md)
- [Security defaults hardening](./security-defaults-hardening.md)
