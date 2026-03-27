# Quality Guide — Music Platform API

This document covers the testing strategy and CI pipeline overview.

> For environment setup and how to run the app, see [SETUP.md](./SETUP.md).

---

## 🧪 Tests

> **Under development.**

---

## 🚀 CI Overview

The GitHub Actions workflow (`.github/workflows/deploy.yml`) runs on every PR and push to `main`. It has two jobs: a **validation job** (compile check, Docker build, Helm lint, Terraform validate) and a **deploy job** (image push, Terraform apply, Helm upgrade, Istio manifests, rollout check). If `KUBE_CONFIG_DATA` is absent, deploy is skipped with an explicit notice rather than failing.

For triggers, full job steps, required secrets, and troubleshooting, see [`github-actions.md`](./cicd/github-actions.md).

---

## 🔗 Related documents

- [Setup guide](./SETUP.md)
- [GitHub Actions guide](./cicd/github-actions.md)
- [Development Log](./DEVELOPMENT_LOG.md)
