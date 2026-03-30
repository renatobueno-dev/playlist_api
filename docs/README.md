# Documentation

> Topic-based reference for the Music Platform API. Each guide covers one area of the stack independently — navigate by topic below.

## 📋 Project-wide guides

| File | Description |
| --- | --- |
| [CHANGELOG.md](../CHANGELOG.md) | Notable changes per version — Added, Changed, Fixed |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Data model, layer structure, and application-level design decisions |
| [INFRA_DECISIONS.md](./INFRA_DECISIONS.md) | Kubernetes, Istio, Terraform, and CI/CD design decisions |
| [SETUP.md](./SETUP.md) | Environment variables and local/Docker/Kubernetes setup |
| [QUALITY.md](./QUALITY.md) | Testing guide and CI overview |
| [API.md](./API.md) | Stable API endpoint reference with schemas and status codes |
| [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md) | Development journey — reasoning, decisions, and corrections per stage |
| [DEVELOPMENT_DIARY.md](./DEVELOPMENT_DIARY.md) | Component-level decisions and reasoning — the why behind each technical choice |
| [DEVELOPMENT_LOG_RESTART.md](./DEVELOPMENT_LOG_RESTART.md) | Historical log of the unpushed commit execution window before guidance restart |
| [DEVELOPMENT_DIARY_RESTART.md](./DEVELOPMENT_DIARY_RESTART.md) | Restart rationale, execution reset context, and guardrails for the next cycle |

## 🎵 Domain

| File | Description |
| --- | --- |
| [domain-scope.md](./domain/domain-scope.md) | Domain model fields and relationship decisions for `Song` and `Playlist` |
| [crud-endpoint-plan.md](./domain/crud-endpoint-plan.md) | CRUD route planning artifact — methods, schemas, status codes, and implementation order |

## 🐳 Containers

| File | Description |
| --- | --- |
| [docker-guide.md](./containers/docker-guide.md) | Docker image build and validation — Steps A–C |
| [compose-guide.md](./containers/compose-guide.md) | Docker Compose multi-service stack — Steps D–E |

## ☸️ Kubernetes

| File | Description |
| --- | --- |
| [k8s-concept-map.md](./kubernetes/k8s-concept-map.md) | Docker/Compose → Kubernetes resource concept translation |
| [helm-guide.md](./kubernetes/helm-guide.md) | Helm chart structure, values, and install/lint commands |

## 🕸️ Istio

| File | Description |
| --- | --- |
| [readiness.md](./istio/readiness.md) | Istio readiness checklist and pre-install validation |
| [traffic.md](./istio/traffic.md) | Gateway, VirtualService, and DestinationRule resilience configuration |
| [security.md](./istio/security.md) | mTLS PeerAuthentication and AuthorizationPolicy rules |

## 🔄 CI/CD

| File | Description |
| --- | --- |
| [github-actions.md](./cicd/github-actions.md) | GitHub Actions workflow: triggers, build/push, and deploy steps |

## 🏗️ Terraform

| File | Description |
| --- | --- |
| [scope-and-boundary.md](./terraform/scope-and-boundary.md) | Terraform ownership boundary, Helm separation matrix, and minimum locked scope |
| [flow-integration.md](./terraform/flow-integration.md) | Integrating Terraform into the full Helm/Istio/CI pipeline |

## 🔧 Post-checkpoint fixes

| File | Description |
| --- | --- |
| [fixes/README.md](./fixes/README.md) | Index and overview of all post-checkpoint remediation work |

## 🔍 Troubleshooting

| File | Description |
| --- | --- |
| [troubleshooting/errors-session-register.md](./troubleshooting/errors-session-register.md) | Session-scoped error register — observed CI, Terraform, and local tooling errors with root-cause groups |
