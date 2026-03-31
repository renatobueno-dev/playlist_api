# Quality Guide — Music Platform API

This document covers the testing strategy and CI pipeline overview.

> For environment setup and how to run the app, see [SETUP.md](./SETUP.md).

---

## 🧪 Tests

The API contract test suite is part of the implemented project baseline, not an optional follow-up.

Contract tests are implemented for:

- root and health availability
- songs CRUD behavior
- playlists CRUD behavior
- playlist-song relationship behavior
- focused negative-path contract validation

Test execution is intentionally isolated from the normal runtime path:

- `tests/conftest.py` forces a disposable SQLite `DATABASE_URL`
- each test run resets schema state for repeatable results
- local runtime database state is not reused by the test suite

Local repeatability check:

```bash
./scripts/verify-local-tests.sh 3
```

Direct single-run command:

```bash
./.venv/bin/python -m pytest -q tests
```

---

## 🚀 CI Overview

The GitHub Actions workflow (`.github/workflows/deploy.yml`) runs on every PR and push to `main`. It has two jobs: a **validation job** (API contract tests, compile check, Docker build, Helm lint, Terraform validate) and a **deploy job** (image push, Terraform apply, Helm upgrade, Istio manifests, rollout check). If `KUBE_CONFIG_DATA` is absent, deploy is skipped with an explicit notice rather than failing.

For triggers, full job steps, required secrets, and troubleshooting, see [`github-actions.md`](./cicd/github-actions.md).

---

## 🔗 Related documents

- [Setup guide](./SETUP.md)
- [GitHub Actions guide](./cicd/github-actions.md)
- [Development Log](./DEVELOPMENT_LOG.md)
