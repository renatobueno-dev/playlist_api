# GitHub Actions

> Documents the CI/CD workflow: triggers, validation steps, build/push pipeline, and deploy sequence. Covers required secrets and known troubleshooting cases.

---

Automates validation, build/push, and deployment into a reproducible CI/CD workflow.

## 📄 Workflow file

- `.github/workflows/deploy.yml`

## ⏰ When automation runs

1. `pull_request`:
   - Runs validation only.
2. `push` on `main`:
   - Runs validation, image build/push, and deploy.
3. `workflow_dispatch`:
   - Allows manual workflow execution from GitHub UI.
   - Deploy still runs only on `refs/heads/main` because the deploy job is gated by branch condition.
   - Manual runs from non-`main` refs execute validation but skip deploy.

## 🔧 What it checks/builds/deploys

Validation job:

- Checkout repository with `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (pinned commit).
- Install Python dependencies.
- Compile Python modules (`python -m compileall app`).
- Build Docker image (validation build).
- Install Helm and Terraform CLIs.
  - Uses pinned versions and retry-enabled downloads to reduce transient network failures.
- Run `helm lint`.
- Render chart with `helm template`.
- Run Terraform checks:
  - `terraform fmt -check`
  - `terraform init -backend=false`
  - `terraform validate`

Deploy job:

- Build and push API image to GHCR:
  - `ghcr.io/<owner>/music-platform-api:<sha>`
  - `ghcr.io/<owner>/music-platform-api:latest`
- Install `kubectl`, Helm, and Terraform CLIs.
  - Uses pinned versions and retry-enabled downloads.
- Configure kubeconfig from repository secret `KUBE_CONFIG_DATA` (base64 kubeconfig).
- Apply Terraform foundation:
  - `terraform init`
  - optional `terraform import` for pre-existing namespace
  - `terraform apply` for namespace baseline and labels
- Run `helm upgrade --install` with image repo/tag override.
- Apply Istio manifests:
  - `k8s/istio/traffic-management.yaml`
  - `k8s/istio/security-policies.yaml`
- Verify deployment and policy resources using `kubectl rollout status` and `kubectl get`.

Deploy secret guard:

- Deploy job runs a precheck step.
- If `KUBE_CONFIG_DATA` is missing, deploy steps are skipped and the workflow reports:
  - `::notice::Skipping deploy because KUBE_CONFIG_DATA is not configured.`

## 🔐 Required GitHub configuration

1. Repository secret:
   - `KUBE_CONFIG_DATA`: base64-encoded kubeconfig with cluster access.

   **Format:** standard `kubeconfig` file encoded as a single base64 string. The deploy job decodes it at runtime:
   ```bash
   echo "${KUBE_CONFIG_DATA}" | base64 -d > "${HOME}/.kube/config"
   ```
   **How to generate it** (from a machine with cluster access):
   ```bash
   base64 < ~/.kube/config | tr -d '\n'
   ```
   Copy the output and add it as a repository secret at:
   `Settings → Secrets and variables → Actions → New repository secret`

   If the secret is absent, deploy steps are skipped with a notice — see "Deploy secret guard" above.
2. Workflow permissions:
   - `packages: write` for pushing to GHCR.
3. Cluster prerequisites:
   - Istio installed and healthy.
   - Namespace and resources allowed by cluster RBAC.
4. Action runtime compatibility:
   - Workflow sets `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`.
   - Helm/Terraform setup is handled by CLI steps to reduce dependency on deprecated Node.js 20 actions.
5. Tooling stability:
   - Workflow pins CLI versions (`kubectl`, `helm`, `terraform`) and uses retry flags for download commands.

## 📊 Success and failure signals in logs

Success indicators:

- `Validate Build And Manifests` job green.
- `Build Push And Deploy` job green.
- Rollout commands report:
  - `deployment "music-platform-api" successfully rolled out`
  - `partitioned roll out complete` for DB statefulset.
- Final `kubectl get` shows pods/resources in expected namespace.

Failure indicators:

- Missing secret:
  - Deploy skipped notice: `Skipping deploy because KUBE_CONFIG_DATA is not configured.`
- Image push failures from GHCR auth/permissions.
- Helm upgrade failures (template, chart, or kube access issues).
- Terraform failures (provider init/import/apply errors).
- Rollout timeout failures from unhealthy pods.
- Istio manifest apply errors (CRD missing, validation failure, RBAC).

## 🐛 Known CI troubleshooting case

Symptom:

- Terraform install step fails with:
  - `error: cannot delete old terraform`
  - `Is a directory`
  - `Process completed with exit code 50`

Cause:

- The repository contains a `terraform/` directory.
- Unzipping Terraform binary directly in workspace creates a filename collision with that directory.

Implemented fix in workflow:

- Download Terraform zip into a temporary directory.
- Unzip into that temporary directory.
- Install binary from temporary directory to `/usr/local/bin`.

---

## 🔗 Related documents

- [Terraform integration flow](../terraform/flow-integration.md)
- [Quality guide](../QUALITY.md)
- [Architecture decisions](../ARCHITECTURE.md)
