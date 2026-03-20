# Stage 4 - Terraform vs Helm Separation (Phase 5, Step 2)

This step defines the operational boundary between Terraform and Helm.

## Core rule

- Helm manages the application release.
- Terraform manages environment and foundational infrastructure.

## Ownership matrix

Terraform owns:

1. Platform prerequisites
   - Namespace existence (`music-platform`).
   - Namespace baseline labels/annotations (for example Istio injection label).
2. Environment-level infrastructure
   - Shared resources that must exist before app deployment.
3. Foundation state lifecycle
   - `terraform plan/apply/destroy` for infrastructure baseline.

Helm owns:

1. Application workloads
   - API Deployment/Service.
   - DB StatefulSet/Service.
2. Release values and rollout
   - Image tag changes.
   - Replica and probe tuning.
3. App release lifecycle
   - `helm upgrade --install` as the deployment path.

GitHub Actions owns:

1. Pipeline execution
   - Build, validate, and deploy sequence.
2. Orchestration
   - Runs Helm deploy after prerequisites are satisfied.

## Anti-conflict rules

1. Do not manage the same Kubernetes object from both Terraform and Helm.
2. Keep Terraform focused on long-lived baseline resources.
3. Keep Helm focused on application release resources.
4. If a resource changes ownership, migrate it explicitly (import/state move) before dual-management risk appears.

## Practical checkpoint for this project

Current project intent:

- Terraform target scope (initial): namespace and namespace labels/annotations.
- Helm target scope: all chart-managed app resources in `helm/music-platform`.
- Istio app-level manifests remain in app delivery path (`k8s/istio`) unless future scope changes.

If these boundaries are respected, Step 2 is complete.
