# Security Toolchain Guide

This document defines the repository's security-validation rollout, the boundary for each candidate tool, and the reason `trivy` is being staged separately from the first enforced layer.

> For the broader repository quality model, see [QUALITY.md](./QUALITY.md). For the implementation record of the overall tooling stack, see [QUALITY_IMPLEMENTATION.md](./QUALITY_IMPLEMENTATION.md).

---

## 🎯 Purpose

The repository already has strong formatting, static analysis, infrastructure validation, and runtime checks.

The security-toolchain rollout adds the missing signals those layers do not provide:

- committed secret detection
- dependency vulnerability auditing
- broken-link detection for docs
- Python security-pattern scanning
- later, infrastructure and image security scanning

The intent is to add **new signal**, not duplicate what Ruff, Pylint, Radon, Helm, Terraform, or Docker validation already do.

---

## ✅ Current rollout status

| Tool        | Status             | Repo role                              |
| ----------- | ------------------ | -------------------------------------- |
| `gitleaks`  | Implemented        | secret scanning                        |
| `pip-audit` | Implemented        | Python dependency vulnerability audit  |
| `lychee`    | Implemented        | documentation link integrity           |
| `bandit`    | Implemented, tuned | Python security-pattern scan           |
| `trivy`     | Planned next phase | image and infrastructure security scan |

The first enforced security layer is intentionally:

- `gitleaks`
- `pip-audit`
- `lychee`
- tuned `bandit`

`trivy` remains the next phase because the repo still needs an explicit posture decision around current Helm/PostgreSQL security findings before it becomes a blocking gate.

---

## 🧩 Current implementation decisions

### `gitleaks`

Current behavior:

- local `security` runs scan the **current working tree snapshot**
- CI runs scan **git history** with `GITLEAKS_MODE=git`

Reason:

- local development benefits from checking what is in the checkout right now
- CI should be the stronger historical guardrail

Implementation note:

- the local scan copies tracked and non-ignored files into a temporary snapshot before scanning
- this avoids crawling `.venv/`, `.tools/`, and other local cache directories

### `pip-audit`

Current behavior:

- audits both pinned dependency files:
  - [`../requirements.txt`](../requirements.txt)
  - [`../requirements-dev.txt`](../requirements-dev.txt)

Reason:

- the repo ships pinned runtime and development dependencies
- vulnerability auditing adds signal that Ruff, Pylint, and Radon do not cover

### `lychee`

Current behavior:

- checks:
  - [`../README.md`](../README.md)
  - [`../CHANGELOG.md`](../CHANGELOG.md)
  - [`./`](./)
- excludes:
  - `mailto:`
  - loopback/localhost URLs
  - `playcatch.local`

Reason:

- the repo is documentation-heavy
- many URLs in the docs are intentionally local/runtime-only examples and should not fail link checks

Portability note:

- the current upstream `lychee` release does not publish a pinned macOS x86_64 tarball
- for this repo, `lychee` is run through its Docker image in the shared tool wrapper to keep the command reproducible across local development and CI

### `bandit` (tuned)

Current behavior:

- scans:
  - [`../app/`](../app/)
  - [`../migrations/`](../migrations/)
- does **not** currently gate on [`../scripts/`](../scripts/) or [`../tests/`](../tests/)

Reason:

- the exploratory run showed that test files only added `assert` noise
- the repo helper script [`../scripts/check-text-hygiene.py`](../scripts/check-text-hygiene.py) produced low-value `subprocess` warnings that do not represent runtime application risk
- the initial tuned scope keeps Bandit focused on application and migration code

---

## ▶️ Local commands

Run only the security layer:

```bash
./scripts/check-quality.sh security
```

Run the full repository stack:

```bash
./scripts/check-quality.sh all
```

The security layer is read-only, like the other `check-quality.sh` layers.

---

## 🚀 CI design

The GitHub Actions workflow adds a dedicated **Security Validation** job.

That job currently runs:

- `GITLEAKS_MODE=git ./scripts/check-quality.sh security`

This means CI uses the stronger git-history secret scan while keeping the rest of the security commands identical to local usage.

---

## 🛡️ `trivy` next phase

`trivy` is the next planned security expansion, but it is not yet a blocking gate.

Planned scope:

- `trivy config` for:
  - `Dockerfile`
  - `docker-compose.yml`
  - [`../terraform/`](../terraform/)
  - [`../helm/music-platform/`](../helm/music-platform/)
- `trivy image` for the built `music-platform-api:quality` image

Reason it is deferred:

- the exploratory run produced a small but real set of Helm/PostgreSQL security findings
- at least one is not a pure false positive and needs a deliberate hardening-or-acceptance decision
- that deserves its own focused pass instead of being quietly hidden during the first rollout

Current known posture question from the exploratory run:

- the DB StatefulSet currently keeps `readOnlyRootFilesystem: false`

That may be acceptable for the PostgreSQL image in this project, but it should be a conscious decision before `trivy` becomes an enforced blocking layer.

---

## 📌 Recommended next step

After the first security layer has stayed green for a short period:

1. add `trivy config`
2. decide whether to harden or explicitly document/ignore the PostgreSQL-related findings
3. add `trivy image` after the existing Docker build

That keeps the rollout incremental and avoids turning the new security layer into a noisy catch-all.

---

## 🔗 Related documents

- [QUALITY.md](./QUALITY.md)
- [QUALITY_IMPLEMENTATION.md](./QUALITY_IMPLEMENTATION.md)
- [GitHub Actions guide](./cicd/github-actions.md)
- [SECRETS_OWNERSHIP.md](./SECRETS_OWNERSHIP.md)
