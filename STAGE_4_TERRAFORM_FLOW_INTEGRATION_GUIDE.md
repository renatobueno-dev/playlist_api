# Stage 4 - Terraform Integration With Existing Flow (Phase 5, Step 4)

This step integrates Terraform as a natural extension of the current Stage 4 delivery model.

## Integrated delivery sequence

1. Terraform foundation
   - Manage namespace baseline (`music-platform`) and required labels (Istio injection).
2. Helm application release
   - Deploy API and DB chart resources.
3. Istio application integration
   - Apply traffic and security manifests.
4. Rollout verification
   - Confirm pods, routes, and policies are healthy.

This keeps each layer focused and ordered by dependency.

## Responsibility alignment

- Terraform:
  - Environment baseline and prerequisites.
- Helm:
  - App release packaging and rollout.
- Istio manifests:
  - Runtime traffic/security behavior for the app.
- GitHub Actions:
  - Executes these layers in sequence and reports results.

## CI/CD fit

The workflow now includes Terraform in both paths:

1. Validation job:
   - `terraform fmt -check`
   - `terraform init -backend=false`
   - `terraform validate`
2. Deploy job:
   - `terraform init`
   - optional `terraform import` for pre-existing namespace
   - `terraform apply` for baseline resources
   - Helm deploy
   - Istio manifest apply
   - rollout/resource verification

## Why this integration is coherent

- It preserves existing Helm + Istio behavior.
- It avoids Terraform/Helm object overlap.
- It makes Terraform useful immediately with minimum safe scope.
- It keeps failure diagnostics explicit in workflow logs by layer.
