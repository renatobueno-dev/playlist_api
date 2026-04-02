# Quality Implementation Record

This document records what was implemented to introduce the repository's full-quality tooling stack.

> Use [QUALITY.md](./QUALITY.md) as the living policy and command reference. Use [SECURITY_TOOLCHAIN.md](./SECURITY_TOOLCHAIN.md) for the dedicated security-layer rollout. Use this file as the implementation history for what changed in the repo.

---

## 🎯 Purpose

The quality stack was introduced with three goals:

- keep one tool per responsibility
- make local quality commands predictable
- split CI feedback into readable layers instead of one large generic job

The most important boundary is still explicit:

> **Ruff does not replace Pylint or Radon in this project.**

Ruff owns formatting and fast linting. Pylint remains the stricter Python policy layer. Radon remains the complexity and maintainability layer.

### Correction to the original framing

The stricter intended meaning of **full-quality** for this project is:

- default `pylint` findings are primary
- default `radon` findings are primary
- other tools are complementary refinements

That means the core Python cleanup goal is not just "green CI with many tools." It is to work down what default `pylint` and default `radon` say about the codebase, then use the other tools to keep the rest of the repository clean and consistent.

---

## ✅ What was added

### Repository-level configuration

The following configuration files were added to support the quality stack:

| File                                                       | Purpose                                                                 |
| ---------------------------------------------------------- | ----------------------------------------------------------------------- |
| [`../ruff.toml`](../ruff.toml)                             | Ruff formatting, import sorting, and fast lint configuration            |
| [`../.editorconfig`](../.editorconfig)                     | Shared text hygiene defaults across docs, YAML, shell, and ignore files |
| [`../.markdownlint-cli2.yaml`](../.markdownlint-cli2.yaml) | Markdown lint rules                                                     |
| [`../.yamllint.yml`](../.yamllint.yml)                     | YAML lint rules for plain YAML                                          |
| [`../.prettierrc.json`](../.prettierrc.json)               | Prettier formatting rules for Markdown and YAML                         |
| [`../.prettierignore`](../.prettierignore)                 | Paths excluded from Prettier formatting                                 |
| [`../.pre-commit-config.yaml`](../.pre-commit-config.yaml) | Local fast-check hooks for developers                                   |

### Quality scripts

The following helper scripts were added:

| File                                                               | Purpose                                                                                                          |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| [`../scripts/format-all.sh`](../scripts/format-all.sh)             | Formats the repository using the approved toolchain                                                              |
| [`../scripts/check-quality.sh`](../scripts/check-quality.sh)       | Runs layered validation with `fast`, `python`, `security`, `infra`, `runtime`, or `all`                          |
| [`../scripts/run-quality-tool.sh`](../scripts/run-quality-tool.sh) | Downloads or runs pinned tool entrypoints such as `hadolint`, `dotenv-linter`, `gitleaks`, `lychee`, and `trivy` |

### CI workflow changes

The GitHub Actions workflow in [`./cicd/github-actions.md`](./cicd/github-actions.md) and [`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml) was updated to run four validation layers before deployment:

1. `fast-quality`
2. `python-quality`
3. `security-validation`
4. `runtime-validation`

Only after those succeed does the deployment job run.

---

## 🧩 Tool responsibility boundaries

The final setup keeps each tool in a clear lane:

| Responsibility                        | Tool                            |
| ------------------------------------- | ------------------------------- |
| Python format and fast lint           | Ruff                            |
| Python stricter policy                | Pylint                          |
| Complexity and maintainability        | Radon                           |
| Markdown and plain YAML formatting    | Prettier                        |
| Markdown linting                      | markdownlint-cli2               |
| YAML linting                          | yamllint                        |
| GitHub Actions validation             | actionlint                      |
| Dockerfile linting                    | hadolint                        |
| Shell formatting                      | shfmt                           |
| Shell linting                         | ShellCheck                      |
| `.env.example` validation             | dotenv-linter                   |
| Terraform formatting and validation   | Terraform CLI                   |
| Helm and rendered manifest validation | Helm plus structural validation |
| Generic text hygiene                  | `.editorconfig` plus hooks      |

This separation was intentional so the repo stays understandable as it grows.

---

## 🔧 Existing files adjusted during integration

Adding stricter checks surfaced a few repo changes that were needed so the new gates would pass cleanly:

- [`.env.example`](../.env.example) was reordered to satisfy `dotenv-linter`
- [`../Dockerfile`](../Dockerfile) was adjusted to satisfy `hadolint`
- [`../migrations/env.py`](../migrations/env.py) was aligned with the Ruff and Pylint import boundary
- [`../requirements-dev.txt`](../requirements-dev.txt) was updated with the additional developer tooling
- [`../.gitignore`](../.gitignore) was updated to ignore local tooling/cache artifacts such as `.tools/` and `.pre-commit-cache/`
- multiple Markdown files across [`./`](./) were reformatted to satisfy Prettier and markdownlint

Those edits were part of the implementation work, not unrelated cleanup.

---

## 🛠️ Implementation details worth keeping

Two practical implementation decisions are important for future maintainers:

### Read-only quality runner

`./scripts/check-quality.sh` now behaves as a true checker:

- it validates text hygiene without rewriting files
- it leaves formatting changes to `./scripts/format-all.sh`
- it avoids the surprise of a command named `check` dirtying the working tree

### Local binary-backed hooks

Some pre-commit hooks are usually Docker-backed, which is inconvenient when Docker is not running locally.

To avoid that dependency for fast checks:

- `hadolint` is run through `scripts/run-quality-tool.sh`
- `dotenv-linter` is run through `scripts/run-quality-tool.sh`
- pinned binaries are downloaded into `.tools/bin/`

That keeps local checks reproducible without requiring a live Docker daemon just to lint files.

### Security-layer rollout

The repository now has an initial security-validation layer in [`../scripts/check-quality.sh`](../scripts/check-quality.sh):

- `gitleaks`
- `pip-audit`
- `lychee`
- tuned `bandit`

Implementation details worth preserving:

- local `gitleaks` scans use a temporary snapshot of tracked and non-ignored repo files
- CI `gitleaks` scans use git-history mode
- `lychee` currently runs through its Docker image in [`../scripts/run-quality-tool.sh`](../scripts/run-quality-tool.sh) because the pinned upstream release used here does not publish a macOS x86_64 tarball
- `bandit` is intentionally scoped to `app/` and `migrations/` so helper-script subprocess noise does not dominate the signal

`trivy` support has been prepared in the shared tool runner, but it is intentionally not an enforced gate yet. The repo documents it as the next phase so the PostgreSQL/Helm security posture can be reviewed deliberately before it becomes blocking.

### Cluster-free rendered-manifest validation

Rendered Helm and Istio manifests are validated structurally without requiring a Kubernetes cluster.

The validation flow checks that rendered YAML:

- parses successfully
- contains mapping documents
- includes `apiVersion`
- includes `kind`
- includes `metadata.name`

This gives the repo a meaningful manifest sanity check while keeping validation portable in local development and CI.

---

## 🧪 Verification status

The repository was previously verified under the earlier checkpoint workflow with the layered quality runner:

```bash
./scripts/check-quality.sh all
```

That earlier run passed end-to-end, including:

- fast formatting and lint checks
- `pylint`
- `radon cc`
- `radon mi`
- contract tests
- Python compile check
- Docker image build
- Helm lint and render validation
- Istio render validation
- Terraform format and validation

Notable results from that earlier checkpoint run:

- `pylint` score: `10.00/10`
- `radon` average complexity: `A`
- `pytest`: `38 passed`
- Docker build: passed
- Terraform validate: passed
- Helm lint: passed with informational guidance that an icon is recommended in `Chart.yaml`

After the switch to default `pylint` and default `radon`, the verification commands should be rerun. That rerun has not been executed in this edit pass.

### Current implementation note

The repo's current automation now follows the stricter target directly:

- `pylint` runs with default behavior in the Python-quality layer
- `radon` runs with default `cc` and `mi` commands in the Python-quality layer
- the codebase changes in this implementation record were aimed at the concrete findings those default commands reported

That distinction matters:

- the implemented workflow now matches the intended "full-quality" Python baseline instead of only pointing to it conceptually
- a fresh validation pass is still the next step before claiming the new default-baseline workflow is fully green

---

## 📚 Related documents

- [QUALITY.md](./QUALITY.md)
- [SECURITY_TOOLCHAIN.md](./SECURITY_TOOLCHAIN.md)
- [cicd/github-actions.md](./cicd/github-actions.md)
- [STATIC_ANALYSIS.md](./STATIC_ANALYSIS.md)
- [README.md](../README.md)
