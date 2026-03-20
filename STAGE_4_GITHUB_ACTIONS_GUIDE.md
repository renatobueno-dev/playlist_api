# Stage 4 - GitHub Actions Automation (Phase 4)

This phase turns manual deployment steps into a reproducible CI/CD workflow.

## Workflow file

- `.github/workflows/deploy.yml`

## When automation runs

1. `pull_request`:
   - Runs validation only.
2. `push` on `main`:
   - Runs validation, image build/push, and deploy.
3. `workflow_dispatch`:
   - Allows manual deployment run from GitHub UI.

## What it checks/builds/deploys

Validation job:

- Install Python dependencies.
- Compile Python modules (`python -m compileall app`).
- Build Docker image (validation build).
- Run `helm lint`.
- Render chart with `helm template`.

Deploy job:

- Build and push API image to GHCR:
  - `ghcr.io/<owner>/music-platform-api:<sha>`
  - `ghcr.io/<owner>/music-platform-api:latest`
- Configure kubeconfig from repository secret `KUBE_CONFIG_DATA` (base64 kubeconfig).
- Ensure namespace exists and has `istio-injection=enabled`.
- Run `helm upgrade --install` with image repo/tag override.
- Apply Istio manifests:
  - `k8s/istio/traffic-management.yaml`
  - `k8s/istio/security-policies.yaml`
- Verify deployment and policy resources using `kubectl rollout status` and `kubectl get`.

Deploy secret guard:

- If `KUBE_CONFIG_DATA` is missing, deploy job is skipped and workflow reports a warning job (`Deploy Skipped (Missing Secret)`).

## Required GitHub configuration

1. Repository secret:
   - `KUBE_CONFIG_DATA`: base64-encoded kubeconfig with cluster access.
2. Workflow permissions:
   - `packages: write` for pushing to GHCR.
3. Cluster prerequisites:
   - Istio installed and healthy.
   - Namespace and resources allowed by cluster RBAC.
4. Action runtime compatibility:
   - Workflow sets `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` to avoid Node.js 20 deprecation warnings.

## Success and failure signals in logs

Success indicators:

- `Validate Build And Manifests` job green.
- `Build Push And Deploy` job green.
- Rollout commands report:
  - `deployment "music-platform-api" successfully rolled out`
  - `partitioned roll out complete` for DB statefulset.
- Final `kubectl get` shows pods/resources in expected namespace.

Failure indicators:

- Missing secret:
  - Deploy skipped warning: `Skipping deploy because KUBE_CONFIG_DATA is not configured.`
- Image push failures from GHCR auth/permissions.
- Helm upgrade failures (template, chart, or kube access issues).
- Rollout timeout failures from unhealthy pods.
- Istio manifest apply errors (CRD missing, validation failure, RBAC).
