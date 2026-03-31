# Terraform State Management Policy

> Defines how Terraform state is expected to behave in this repository: ownership expectations, collaboration discipline, locking behavior, and recovery thinking.

---

## 🎯 Policy goal

`terraform/backend.tf` already configures persistent state storage, but backend configuration alone is not enough for safe team operation.

This policy clarifies:

- who is expected to run `plan/apply`,
- how concurrent changes are avoided,
- how lock handling should work in practice,
- what to do when state or cluster reality diverge.

---

## 🧱 Current backend baseline

| Item | Current baseline | Source |
| --- | --- | --- |
| Backend type | `kubernetes` | `terraform/backend.tf` |
| Backend namespace | `kube-system` | `terraform/backend.tf` |
| State secret suffix | `music-platform` | `terraform/backend.tf` |
| Lock wait policy in CI | `-lock-timeout=120s` | `.github/workflows/deploy.yml` |

Backend configuration gives persistent location and locking support. Operational safety still depends on disciplined execution.

---

## 👥 Collaboration modes

### 1) Single-user local mode (learning / local cluster)

- Manual `terraform plan/apply` is allowed.
- Purpose: local experimentation against personal cluster context.
- Expectation: keep operations scoped to repository-managed resources only.

### 2) Shared environment mode (mainline delivery)

- CI deploy workflow is the expected writer for Terraform state.
- Human manual `apply` should be exception-only (break-glass recovery).
- Expectation: avoid competing writes between local terminals and CI runs.

---

## 🔒 Locking expectations in practice

1. Treat Terraform as single-writer at any moment.
2. Keep lock timeout explicit on state-changing operations in shared environments.
3. If lock wait expires, do not bypass lock blindly. Investigate active writer first.
4. Prefer rerun after writer completion instead of forcing lock release.

Practical rule: lock conflicts are usually a coordination signal, not a Terraform bug.

---

## 🧭 Operational discipline

### Do

- Use `terraform init` before plan/apply in each environment.
- Use `terraform validate` and formatting checks before state-changing runs.
- Keep Terraform scope limited to namespace baseline resources in this project (namespace, baseline labels, baseline `ResourceQuota`, baseline `LimitRange`).
- Import pre-existing namespace resources before first managed apply when required.

### Do not

- Run manual apply in shared environments while CI deploy is active.
- Expand Terraform ownership into Helm-managed workload objects without explicit migration plan.
- Modify backend settings ad hoc per developer machine for shared state flows.

---

## ♻️ Recovery thinking

| Symptom | Likely cause | Recovery approach |
| --- | --- | --- |
| `Error acquiring the state lock` | Another writer active or stale lock | Wait for active run; retry. If stale lock is confirmed, coordinate and resolve lock intentionally. |
| `Already exists` during apply | Resource exists in cluster but not in state | Import existing resource into state, then rerun apply. |
| Drift after manual cluster change | Out-of-band mutation | Run plan to inspect drift; reconcile via Terraform-managed path. |
| Backend init/access failure | Kube context or RBAC issue | Re-check kubeconfig context/permissions before rerunning init/apply. |

Recovery principle: restore Terraform as source of truth, not ad hoc manual patching.

---

## ✅ Completion criteria for Step 19

Step 19 is satisfied when:

1. State writer expectations are clear for local vs shared environments.
2. Locking behavior is treated as an operational policy, not a hidden implementation detail.
3. Basic recovery paths are documented for lock/conflict/drift conditions.
4. The policy is linked from Terraform and roadmap docs for discoverability.

---

## 🔗 Related documents

- [Terraform scope and boundary](./scope-and-boundary.md)
- [Terraform integration flow](./flow-integration.md)
- [GitHub Actions guide](../cicd/github-actions.md)
- [Infrastructure decisions](../INFRA_DECISIONS.md)
