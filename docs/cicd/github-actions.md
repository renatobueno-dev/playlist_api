# GitHub Actions

> Documents the CI/CD workflow: triggers, validation jobs, deploy flow, required secrets, and known troubleshooting cases.

---

Automates validation, build/push, and deployment into a reproducible CI/CD workflow.

## 📄 Workflow file

- `.github/workflows/deploy.yml`

## ⏰ When automation runs

1. `pull_request`
   - Runs validation jobs only.
2. `push` on `main`
   - Runs validation jobs, image build/push, and deploy.
3. `workflow_dispatch`
   - Allows manual execution from the GitHub UI.
   - Deploy still runs only on `refs/heads/main`.

## 🔁 Concurrency behavior

- Workflow concurrency is enabled.
- Group key: `${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}`
- Meaning:
  - repeated runs for the same PR or ref are coalesced into one active run
  - older in-progress runs are canceled when a newer run starts for that same group

## 🧪 Validation job layout

The workflow now splits validation into four readable jobs instead of one large generic gate.

### 1. Fast Quality Checks

Purpose: fast formatting and lint feedback across Python, docs, YAML, shell, workflow, Dockerfile, and `.env.example`.

Runs:

- `./scripts/check-quality.sh fast`

That layer includes:

- text hygiene hooks
- Prettier check for Markdown and plain YAML
- `markdownlint-cli2`
- `yamllint`
- `ruff format --check`
- `ruff check`
- `shfmt` check
- `shellcheck`
- `actionlint`
- `hadolint`
- `dotenv-linter`

### 2. Python Quality Policy

Purpose: run the default `pylint` and default `radon` baseline in a readable layer separate from fast lint.

Runs:

- `./scripts/check-quality.sh python`

That layer includes:

- `pylint`
- `radon cc`
- `radon mi`

This is intentional:

- Ruff remains the fast formatter/linter layer
- Pylint remains the primary static-analysis baseline
- Radon remains the complexity/maintainability baseline

### 3. Security Validation

Purpose: run the repository's dedicated security checks without mixing them into the fast formatter/linter feedback.

Runs:

- `GITLEAKS_MODE=git ./scripts/check-quality.sh security`

That layer includes:

- `gitleaks` git-history scan
- `pip-audit`
- `lychee`
- tuned `bandit`

Boundary notes:

- local runs use current-tree `gitleaks` scanning, but CI uses the stronger git-history mode
- `lychee` runs with repo-specific exclusions for local/runtime-only documentation URLs
- `bandit` is tuned to application and migration Python so low-value helper/test noise does not dominate the job

### 4. Runtime Validation

Purpose: validate behaviour, container lifecycle, and infrastructure manifests.

Runs:

- `./scripts/check-quality.sh runtime`
- `./scripts/check-quality.sh infra`

That layer includes:

- API contract tests
- Python compile check
- Docker image build
- `docker compose config`
- `helm lint`
- rendered Helm validation in default mode
- rendered Helm validation in external-secret mode
- rendered Istio manifest validation
- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`

## 🚀 Deploy job

Deploy runs only after all four validation jobs pass and the ref is `main`.

Deploy responsibilities:

- build and push the API image to GHCR
- install `kubectl`, Helm, and Terraform CLIs
- configure kubeconfig from `KUBE_CONFIG_DATA`
- apply Terraform foundation
- verify the runtime DB secret exists and includes the required keys
- run `helm upgrade --install`
- render and apply Istio manifests
- verify rollout and policy resources

## 🔐 Required GitHub configuration

1. Repository secret
   - `KUBE_CONFIG_DATA`: base64-encoded kubeconfig with cluster access
2. Repository variable (optional)
   - `DB_EXISTING_SECRET_NAME`: runtime Kubernetes Secret name consumed by Helm deploy
   - default if omitted: `music-platform-secret`
3. Cluster runtime secret prerequisite
   - the secret referenced by `DB_EXISTING_SECRET_NAME` must exist in the deploy namespace
   - required keys:
     - `DATABASE_URL`
     - `POSTGRES_PASSWORD`
4. Workflow permissions
   - `packages: write` for pushing to GHCR
5. Cluster prerequisites
   - Istio installed and healthy
   - namespace and resources allowed by cluster RBAC
6. Tooling stability
   - the workflow pins `kubectl`, Helm, Terraform, and `actions/setup-node`
   - all jobs use `ubuntu-24.04` (explicit runner version, not `ubuntu-latest`) for the same reproducibility reason as pinned CLI versions — a silent runner upgrade cannot break the pipeline

## 🔐 Runtime secret ownership note

- GitHub Actions provides deploy access (`KUBE_CONFIG_DATA`) and orchestration only.
- Runtime DB credentials are not injected from GitHub repository secrets.
- Runtime credentials must already exist in-cluster through the external secret referenced by `db.existingSecret`.

## 🧬 Migration behavior

- The deploy workflow does **not** run `alembic upgrade head`.
- Deployment assumes the target database is already migrated to the expected revision.
- If schema is missing or outdated, API pods may fail startup schema validation until migrations are applied.

## 📊 Success and failure signals

Success indicators:

- `Fast Quality Checks` job green
- `Python Quality Policy` job green
- `Security Validation` job green
- `Runtime Validation` job green
- `Build Push And Deploy` job green on `main`
- rollout commands report successful completion

Failure indicators:

- missing `KUBE_CONFIG_DATA`
  - deploy is skipped with `::notice::Skipping deploy because KUBE_CONFIG_DATA is not configured.`
- missing runtime DB secret
  - deploy fails before Helm with clear `::error::` logs
- quality failures
  - specific job fails with its own layer output instead of a generic validation blob
- Helm/Terraform/render failures
  - runtime-validation job fails before deploy is attempted

## 🐛 Known CI troubleshooting case

Symptom:

- Terraform install step fails with:
  - `error: cannot delete old terraform`
  - `Is a directory`
  - `Process completed with exit code 50`

Cause:

- the repository contains a `terraform/` directory
- unzipping the Terraform binary directly in the workspace creates a filename collision

Implemented fix:

- download the Terraform zip into a temporary directory
- unzip there
- install the binary from the temporary directory to `/usr/local/bin`

---

## 🔗 Related documents

- [Quality guide](../QUALITY.md)
- [Security toolchain guide](../SECURITY_TOOLCHAIN.md)
- [Terraform integration flow](../terraform/flow-integration.md)
- [Migration workflow](../MIGRATIONS.md)
- [Architecture decisions](../ARCHITECTURE.md)
