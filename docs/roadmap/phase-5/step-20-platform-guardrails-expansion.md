# 🛡️ Phase 5 — Step 20: Expand Namespace and Platform Guardrails

## 📌 Context

Tests and migrations are now in place, so platform governance can move beyond baseline labels into stronger namespace controls.

Before this step, Terraform managed namespace lifecycle and labels only. Governance intent was documented, but enforceable guardrails were still limited.

## 🎯 Scope decision

Expand Terraform-owned platform baseline with namespace-level guardrails that do not overlap Helm workload ownership:

- `ResourceQuota` baseline
- `LimitRange` baseline

Keep workload objects (Deployment/StatefulSet/Service) under Helm ownership.

## ✅ Implementation

Terraform changes:

- Added baseline guardrail resources in `terraform/main.tf`:
  - `kubernetes_resource_quota_v1.baseline`
  - `kubernetes_limit_range_v1.baseline`
- Added configurable guardrail inputs in `terraform/variables.tf`:
  - `enable_platform_guardrails`
  - `resource_quota_hard`
  - `limit_range_default`
  - `limit_range_default_request`
- Added outputs in `terraform/outputs.tf`:
  - `platform_guardrails_enabled`
  - `resource_quota_name`
  - `limit_range_name`

Documentation updates:

- `docs/terraform/scope-and-boundary.md`
- `docs/terraform/flow-integration.md`
- `docs/INFRA_DECISIONS.md`
- `docs/README.md`
- root `README.md`
- `docs/roadmap/README.md`

## 🔁 Validation

Step 20 validation target:

- Terraform configuration renders validly with guardrails enabled by default.
- Namespace guardrails are clearly separated from Helm-managed workloads.
- Docs describe governance as platform refinement after app confidence (tests + migrations).

## 🐞 Step execution notes (issues)

- Initial Terraform validation failed due to ambiguous map keys in `resource_quota_hard` (`requests.cpu`, `limits.memory`, etc.) because dotted keys must be quoted in HCL maps.
- Fix applied: quoted dotted quota keys in `terraform/variables.tf`, then reran `terraform init -backend=false` and `terraform validate` successfully.
- Main concern handled: quota defaults were chosen to stay above current chart requests/limits, reducing rollout-risk while still enforcing boundaries.

## 🏁 Completion criteria

Step 20 is complete when:

1. namespace/platform guardrails are enforceable, not only conceptual,
2. Terraform remains the owner of platform baseline policy objects,
3. workload ownership boundaries with Helm stay explicit and unchanged.
