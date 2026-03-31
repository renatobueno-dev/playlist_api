# Terraform Integration Flow

> Shows how Terraform fits into the full Terraform → Helm → Istio → Verify delivery sequence and how CI/CD orchestrates each layer.

---

Integrates Terraform as a prerequisite step in the full delivery sequence.

## 🔄 Integrated delivery sequence

1. Terraform foundation
   - Manage namespace baseline (`music-platform`) and required labels (Istio injection plus Pod Security Standards labels).
   - Manage namespace guardrails (`ResourceQuota` and `LimitRange`) for platform-level boundaries.
2. Runtime secret verification
   - Verify external Kubernetes Secret exists in target namespace and exposes required keys for API/DB.
3. Helm application release
   - Deploy API and DB chart resources.
4. Istio application integration
   - Apply traffic and security manifests.
5. Rollout verification
   - Confirm pods, routes, and policies are healthy.

This keeps each layer focused and ordered by dependency.

## 🛠️ CI/CD fit

The workflow now includes Terraform in both paths:

1. Validation job:
   - `terraform fmt -check`
   - `terraform init -backend=false`
   - `terraform validate`
2. Deploy job:
   - `terraform init`
   - optional `terraform import` for pre-existing namespace
   - `terraform apply` for baseline resources and namespace guardrails
   - verify runtime DB secret exists and has required keys (`DATABASE_URL`, `POSTGRES_PASSWORD`)
   - Helm deploy
   - Istio manifest apply
   - rollout/resource verification

### Why `terraform import` runs automatically

The deploy job checks whether the `music-platform` namespace already exists in the cluster before running `terraform apply`:

```bash
if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  terraform -chdir=terraform import ... kubernetes_namespace_v1.music_platform "${NAMESPACE}" || true
fi
```

**Why this is necessary:** if the namespace was created by a previous Helm deploy (`--create-namespace`) or manually, it already exists in the cluster but is not tracked in Terraform state. Running `terraform apply` without importing would cause a conflict — Terraform would try to create an object that already exists.

Importing first reconciles the existing namespace into Terraform state so `apply` can manage it safely. The `|| true` allows the step to continue even if the import had already been done in a previous run (Terraform returns a non-zero exit code when a resource is already in state).

## ✅ Why this integration is coherent

- It preserves existing Helm + Istio behavior.
- It keeps Terraform separated from runtime secret ownership.
- It avoids Terraform/Helm object overlap.
- It makes Terraform useful immediately with minimum safe scope.
- It keeps failure diagnostics explicit in workflow logs by layer.

---

## 🔗 Related documents

- [Terraform scope and boundary](./scope-and-boundary.md)
- [Terraform state management policy](./state-management-policy.md)
- [GitHub Actions guide](../cicd/github-actions.md)
