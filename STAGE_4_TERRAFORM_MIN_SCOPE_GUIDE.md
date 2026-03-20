# Stage 4 - Minimum Valid Terraform Scope (Phase 5, Step 3)

This step locks the smallest valid Terraform scope for checkpoint delivery.

## Decision

The minimum Terraform-managed infrastructure in this project is:

1. `music-platform` Kubernetes namespace.
2. Namespace baseline labels/annotations required for platform behavior:
   - `istio-injection=enabled`

No additional resources are included in the minimum scope.

## Why this is the safest minimum

- It is infrastructure-level, not app-release-level.
- It is a direct prerequisite for Helm deploy and Istio behavior.
- It avoids overlap with Helm chart objects.
- It proves Terraform adds real value without overengineering.

## Explicitly out of minimum scope

Not in Step 3 minimum scope:

1. API/DB workloads and services from Helm chart.
2. App release values and image tag updates.
3. Istio traffic/security policy resources already handled in app delivery.
4. CI/CD pipeline execution logic (remains in GitHub Actions).

## “Done” criteria for Step 3

Step 3 is complete when:

1. The minimum scope is formally documented.
2. The scope is mapped as Terraform-owned and non-overlapping with Helm.
3. Future Terraform implementation starts from namespace + labels only.
