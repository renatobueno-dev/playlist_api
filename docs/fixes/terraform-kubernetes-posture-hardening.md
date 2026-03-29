# Step 5 Fix: Terraform and Kubernetes Posture Hardening

> Tightens Terraform provider constraint, adds namespace Pod Security baseline labels, and makes backend and lock behavior explicit.

---

## 🐛 Problem

Terraform baseline posture was still minimal:

- provider policy was broad (`~> 2.36`);
- namespace baseline labels only guaranteed `istio-injection=enabled`;
- backend and lock behavior were not explicit in code/workflow.

## 🎯 Goal

Make Terraform look like intentional infrastructure code, not a minimal add-on.

## 🔧 Implementation

### 1) Provider policy tightening

File:

- `terraform/versions.tf`

Change:

- At Step 5 implementation time, Kubernetes provider constraint moved from `~> 2.36` to `~> 2.38`.
- In a later follow-up, it was tightened to patch-level `~> 2.38.0` (current baseline in `terraform/versions.tf`).

Reason:

- Removed the broad initial constraint first, then aligned provider policy to patch-level for deterministic behavior.

### 2) Namespace Pod Security baseline

Files:

- `terraform/variables.tf`
- `terraform/main.tf`

Changes:

- Added variables:
  - `pod_security_level` (default `restricted`)
  - `pod_security_version` (default `latest`)
- Extended required namespace labels to include:
  - `pod-security.kubernetes.io/enforce`
  - `pod-security.kubernetes.io/warn`
  - `pod-security.kubernetes.io/audit`
  - `pod-security.kubernetes.io/enforce-version`
  - `pod-security.kubernetes.io/warn-version`
  - `pod-security.kubernetes.io/audit-version`
- Kept required `istio-injection=enabled`.

Reason:

- Namespace baseline now reflects both mesh requirements and Pod Security posture.

### 3) Explicit backend and lock strategy visibility

Files:

- `terraform/backend.tf`
- `.github/workflows/deploy.yml`

Changes:

- Added explicit backend declaration:
  - `backend "kubernetes" { namespace = "kube-system"; secret_suffix = "music-platform" }`
- Added workflow env var:
  - `TERRAFORM_LOCK_TIMEOUT: 120s`
- Added `-lock-timeout` to Terraform `import` and `apply` steps.

Reason:

- Backend behavior is explicit in Terraform code.
- Lock behavior is explicit in deploy commands.

## ✅ Validation

Commands:

```bash
terraform -chdir=terraform fmt
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

Checks:

- Terraform formatting is clean.
- Configuration validates in CI-style mode (`-backend=false`).
- Namespace label set includes Pod Security baseline keys in plan/validation.

---

## 🔗 Related documents

- [Loose ends roadmap](./loose-ends-priority-roadmap.md)
- [Terraform scope and boundary](../terraform/scope-and-boundary.md)
- [Pipeline reproducibility](./pipeline-reproducibility-hardening.md)
