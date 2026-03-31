# Secrets Ownership Boundary — Music Platform API

This document defines who owns secrets in each environment and which layer is allowed to define or inject them.

---

## 🎯 Current ownership decision

Secret delivery ownership is explicitly split by environment:

- **Local development / Docker Compose:** developer-managed secrets (local `.env` and shell environment)
- **Kubernetes shared environments:** externally injected Kubernetes Secret is preferred owner
- **Helm chart-generated Secret:** allowed as fallback for non-shared/demo environments only
- **Controller-synced external manager:** optional later enhancement, not part of the current implementation

This keeps boundary clear while remaining compatible with current chart capabilities (`db.existingSecret` and chart-managed fallback).

---

## 🧭 Ownership model

| Topic | Owner | Allowed definers | Delivery layer |
| --- | --- | --- | --- |
| Local DB credentials | Developer local environment | Local developer | `.env` / shell env vars |
| Compose runtime DB credentials | Developer local environment | Local developer | `docker-compose.yml` environment wiring |
| Kubernetes app DB credentials (preferred) | Pre-created Kubernetes Secret | Platform operator / release operator with cluster access | Secret referenced by Helm via `db.existingSecret` |
| Kubernetes app DB credentials (fallback) | Helm release values at install/upgrade time | Helm operator for that release | `helm/music-platform/templates/secret.yaml` |
| CI cluster access (`KUBE_CONFIG_DATA`) | GitHub repository secrets | Repository admin/maintainer | GitHub Actions secret injection |

---

## 🔐 Origin, injection, rotation, and permissions

### Where secrets originate

- Local/Compose: local operator-provided values.
- Kubernetes preferred path: external pre-created Secret in cluster namespace.
- CI cluster credentials: GitHub Actions secrets store.

### Who injects secrets

- Local/Compose: developer/operator at runtime.
- Kubernetes preferred path: cluster Secret management process (manual or platform process) before Helm deploy.
- Kubernetes fallback path: Helm template renders Secret from release inputs.

### Who rotates secrets

- Local/Compose: developer/operator.
- Kubernetes preferred path: platform/operator managing external Secret.
- Kubernetes fallback path: Helm release operator (through update/redeploy).
- CI `KUBE_CONFIG_DATA`: repository admin/maintainer.

### Who is allowed to define secrets

- Local: machine owner/developer.
- Kubernetes shared environments: platform/release operators with namespace secret permissions.
- GitHub Actions secrets: repository admins/maintainers only.

---

## ✅ Operational rule set

1. For shared cluster environments, set `db.existingSecret` and keep secret values outside chart values.
2. Use chart-managed secret generation only for isolated/demo environments.
3. Never commit real secret values to repository files.
4. Keep CI secrets limited to deployment credentials, not application runtime credentials.

---

## 🔄 Current deploy flow alignment (Helm + Terraform + CI/CD)

Shared-environment deploy flow is now aligned with this policy:

1. Terraform applies namespace baseline and labels only.
2. CI checks deploy access (`KUBE_CONFIG_DATA`).
3. CI verifies runtime secret exists in namespace (`DB_EXISTING_SECRET_NAME`, default `music-platform-secret`).
4. CI verifies required secret keys: `DATABASE_URL` and `POSTGRES_PASSWORD`.
5. Helm deploy consumes that secret through `db.existingSecret`.
6. Istio manifests are applied and rollout is verified.

This keeps ownership coherent:

- Terraform: environment baseline
- Helm: workload deployment
- CI: orchestration and validation
- External Kubernetes Secret: runtime credential source

Current behavior in this repository:

- Shared-environment CI deploy enforces external secret mode.
- Manual Helm installs can still use chart-managed secret fallback when `db.existingSecret` is not set (intended for local/demo flows).

---

## 🚧 Optional later work

- No external secret controller integration is implemented in this repository yet.
- No Vault/SOPS/External Secrets Operator sync flow is part of the current required implementation.

---

## 🔗 Related documents

- [Infrastructure decisions](./INFRA_DECISIONS.md)
- [Setup guide](./SETUP.md)
- [Helm chart guide](./kubernetes/helm-guide.md)
- [GitHub Actions guide](./cicd/github-actions.md)
