# Quality Guide — Music Platform API

This document defines the repository quality stack, the responsibility boundary for each tool, and the local/CI commands that keep the project healthy.

> For environment setup and how to run the app, see [SETUP.md](./SETUP.md). For the workflow-level CI/CD details, see [cicd/github-actions.md](./cicd/github-actions.md). For the security-specific rollout, see [SECURITY_TOOLCHAIN.md](./SECURITY_TOOLCHAIN.md). For the implementation record of what was added to the repo, see [QUALITY_IMPLEMENTATION.md](./QUALITY_IMPLEMENTATION.md).

---

## 🧭 Core Rule

This project keeps **one tool per responsibility**.

That means the Python layer is intentionally split:

- **Ruff** owns formatting, import sorting, and fast linting
- **Pylint** owns the primary static-analysis baseline
- **Radon** owns complexity and maintainability signals

**Explicit rule:** Ruff does **not** replace Pylint or Radon in this repository.

---

## 🥇 Primary Baseline

For the intended **full-quality** standard in this project, the primary static-analysis baseline is:

- default `pylint`
- default `radon`

The main purpose of the Python quality work is to fix what those tools report.

The other tools in this repository are still valuable, but they play a different role:

- Ruff improves formatting and fast feedback
- Markdown, YAML, shell, Docker, and Terraform tools improve repo hygiene
- infrastructure validators improve delivery confidence

Those layers are refinements around the core Python analysis baseline, not replacements for it.

---

## 🧰 Quality Stack

| Responsibility                   | Tool                              | Repo scope                                              |
| -------------------------------- | --------------------------------- | ------------------------------------------------------- |
| Python formatting                | `ruff format`                     | `app/`, `tests/`, `migrations/`                         |
| Python fast lint                 | `ruff check`                      | `app/`, `tests/`, `migrations/`                         |
| Python policy lint               | `pylint`                          | `app/`, `tests/`, `migrations/`                         |
| Python complexity metrics        | `radon cc` / `radon mi`           | `app/`, `tests/`, `migrations/`                         |
| Markdown + plain YAML formatting | Prettier                          | `README.md`, `CHANGELOG.md`, `docs/**/*.md`, plain YAML |
| Markdown lint                    | `markdownlint-cli2`               | Markdown docs                                           |
| YAML lint                        | `yamllint`                        | plain YAML files, excluding Helm templates              |
| GitHub Actions validation        | `actionlint`                      | `.github/workflows/*.yml`                               |
| Dockerfile lint                  | `hadolint`                        | `Dockerfile`                                            |
| Shell format                     | `shfmt`                           | `scripts/*.sh`                                          |
| Shell lint                       | `shellcheck`                      | `scripts/*.sh`                                          |
| `.env` validation                | `dotenv-linter`                   | `.env.example`                                          |
| Secret scanning                  | `gitleaks`                        | repository snapshot locally, git history in CI          |
| Dependency vulnerability audit   | `pip-audit`                       | `requirements.txt`, `requirements-dev.txt`              |
| Documentation link integrity     | `lychee`                          | `README.md`, `CHANGELOG.md`, `docs/`                    |
| Python security scan             | tuned `bandit`                    | `app/`, `migrations/`                                   |
| Docker Compose semantics         | `docker compose config`           | `docker-compose.yml`                                    |
| Terraform format / validate      | Terraform CLI                     | `terraform/`                                            |
| Helm chart sanity                | `helm lint` + rendered validation | `helm/music-platform/`                                  |
| Generic text hygiene             | `.editorconfig` + basic hooks     | mixed text files                                        |

Important YAML boundary:

- `helm/music-platform/templates/` is templated YAML, not plain YAML
- generic YAML formatters/linters do **not** own those templates
- Helm owns validation there through `helm lint` and rendered-manifest checks

Current security rollout note:

- `gitleaks`, `pip-audit`, `lychee`, and tuned `bandit` are now part of the enforced quality stack
- `trivy` is documented as the next security phase, but it is not yet a blocking repository gate

---

## 🏃 Local Developer Flow

### Format the repo

Use the formatter entrypoint when you want the repo rewritten into the expected shape:

```bash
./scripts/format-all.sh
```

What it runs:

- text fixers (`end-of-file`, trailing whitespace, LF endings)
- `ruff format`
- `ruff check --fix`
- Prettier write mode for Markdown and plain YAML
- `shfmt` write mode for shell scripts
- `terraform fmt -recursive`

### Run layered checks

Use the layered quality runner when you want validation without guessing which commands to run:

```bash
./scripts/check-quality.sh fast
./scripts/check-quality.sh python
./scripts/check-quality.sh security
./scripts/check-quality.sh infra
./scripts/check-quality.sh runtime
./scripts/check-quality.sh all
```

`./scripts/check-quality.sh` is intentionally read-only. Use `./scripts/format-all.sh` when you want automatic file rewrites.

Local prerequisites by layer:

- `fast` and `python` assume the project `.venv` is installed with runtime and development dependencies.
- `security` also requires Docker locally because the pinned `lychee` runner is executed through a container wrapper.
- `infra` also requires Docker, Helm, and Terraform in your local PATH.
- `runtime` also requires Docker because the layer builds and validates the container image.

Layer meaning:

- `fast`: read-only text hygiene checks, Prettier, markdownlint, yamllint, Ruff, actionlint, hadolint, shfmt, shellcheck, dotenv-linter
- `python`: `pylint` + `radon`
- `security`: `gitleaks`, `pip-audit`, `lychee`, tuned `bandit`
- `infra`: Docker Compose config, Helm lint/render validation, Istio render validation, Terraform fmt/init/validate
- `runtime`: contract tests, Python compile check, Docker image build
- `all`: the full stack in order

### Pre-commit

The repo also ships a [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) for fast local guardrails.

Install the git hook once per clone:

```bash
python3 -m pre_commit install
```

That hook is intentionally focused on the fast layer, not the full runtime/infrastructure lifecycle.

---

## 🧪 Python Quality Boundary

### Ruff

Ruff is configured in [`ruff.toml`](../ruff.toml) for:

- formatting
- import sorting
- fast correctness/style rules
- lightweight modernization rules

Ruff is intentionally **not** the place for:

- the primary static-analysis baseline owned by default `pylint`
- complexity thresholds
- maintainability scoring

### Pylint

Pylint remains the stricter Python policy layer for this repo:

- the quality runner uses default `pylint` behavior directly
- the repo does not rely on a tuned suppression baseline to make the report pass
- CI now runs it in its own job, so the signal is visible without mixing it into fast lint

### Radon

Radon remains its own metric layer:

```bash
python3 -m radon cc app tests migrations
python3 -m radon mi app tests migrations
```

Those metrics are not represented inside Ruff on purpose.

For this repo's target quality model:

- default `radon` output is part of the real baseline
- the cleanup goal is still to address the complexity and maintainability signals, not to hide them behind other tools

For the detailed cleanup history behind the current Pylint/Radon baseline, see [STATIC_ANALYSIS.md](./STATIC_ANALYSIS.md).

---

## 🔐 Security Layer

The repository now has a dedicated security-validation layer for signals that are outside the normal formatter/linter/static-analysis flow.

Current enforced security checks:

- `gitleaks`
- `pip-audit`
- `lychee`
- tuned `bandit`

Current implementation boundaries:

- local `gitleaks` scans use a temporary snapshot of tracked and non-ignored files
- CI `gitleaks` scans use git-history mode
- `lychee` excludes loopback/local-runtime URLs that are intentionally used as documentation examples
- `bandit` is tuned to `app/` and `migrations/` so helper/test noise does not dominate the security signal

The detailed rollout decisions and the next-step `trivy` plan are documented in [SECURITY_TOOLCHAIN.md](./SECURITY_TOOLCHAIN.md).

---

## 🚀 CI Layers

The GitHub Actions workflow is split into readable validation jobs:

1. **Fast Quality Checks**
   - formatting/lint stack for docs, YAML, shell, Dockerfile, workflows, env sample, and fast Python checks
2. **Python Quality Policy**
   - `pylint`
   - `radon cc`
   - `radon mi`
3. **Security Validation**
   - `gitleaks`
   - `pip-audit`
   - `lychee`
   - tuned `bandit`
4. **Runtime Validation**
   - contract tests
   - compile check
   - Docker build
   - Helm validation
   - Terraform validation
   - rendered-manifest checks

This keeps feedback specific instead of collapsing everything into one generic “quality” job.

---

## 🔗 Related documents

- [SETUP.md](./SETUP.md)
- [SECURITY_TOOLCHAIN.md](./SECURITY_TOOLCHAIN.md)
- [STATIC_ANALYSIS.md](./STATIC_ANALYSIS.md)
- [GitHub Actions guide](./cicd/github-actions.md)
- [LIFECYCLE_VALIDATION.md](./LIFECYCLE_VALIDATION.md)
