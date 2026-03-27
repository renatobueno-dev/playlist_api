# Step 4 Fix: Pipeline Reproducibility Hardening

> Makes CI/CD execution deterministic: workflow action SHA pinning, Python dependency pinning, Postgres image digest pinning, and concurrency protection.

---

## 🐛 Problem

Pipeline and runtime inputs were still partially floating:

- workflow actions were version-tag based (`@v5`, `@v3`, `@v6`);
- no workflow-level concurrency guard existed;
- Python dependencies were unpinned;
- PostgreSQL image references in Compose and Helm were loosely tagged.

## 🎯 Goal

Make repeated CI/CD and runtime execution more deterministic and less fragile.

## 🔧 Implementation

### 1) Workflow concurrency protection

File:

- `.github/workflows/deploy.yml`

Change:

- Added top-level concurrency group:
  - `group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}`
  - `cancel-in-progress: true`

Reason:

- Prevents overlapping runs for the same branch/PR from racing deploy steps.

### 2) Immutable action pinning

File:

- `.github/workflows/deploy.yml`

Changes:

- Pinned actions to commit SHAs:
  - `actions/checkout@93cb6efe18208431cddfb8368fd83d5badbf9bfd`
  - `docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f`
  - `docker/login-action@c94ce9fb468520275223c153574b00df6fe4bcc9`
  - `docker/build-push-action@10e90e3645eae34f1e60eeb005ba3a3d33f178e8`

Reason:

- Removes tag drift from third-party action execution.

### 3) Python dependency pinning

File:

- `requirements.txt`

Changes:

- Added exact versions:
  - `fastapi==0.135.1`
  - `uvicorn[standard]==0.42.0`
  - `sqlalchemy==2.0.48`
  - `psycopg[binary]==3.3.3`

Reason:

- Prevents silent dependency upgrades from changing runtime behavior between runs.

### 4) PostgreSQL image pinning

Files:

- `docker-compose.yml`
- `helm/music-platform/values.yaml`

Changes:

- Pinned Postgres image to immutable digest:
  - `postgres:16-alpine@sha256:20edbde7749f822887a1a022ad526fde0a47d6b2be9a8364433605cf65099416`

Reason:

- Aligns local and cluster DB image resolution to a fixed artifact.

## ✅ Validation

Commands:

```bash
helm lint helm/music-platform
helm template music-platform helm/music-platform >/tmp/helm-step4.yaml
python3 -m compileall app
docker compose config >/tmp/compose-step4.yaml
docker build -t music-platform-api:step4 .
```

Checks:

- Helm renders with pinned Postgres image value.
- Compose config resolves pinned Postgres image reference.
- Docker build uses pinned Python dependency set.
- Workflow file includes concurrency block and SHA-pinned action references.

---

## 🔗 Related documents

- [Loose ends roadmap](./loose-ends-priority-roadmap.md)
- [GitHub Actions guide](../cicd/github-actions.md)
- [Runtime hardening](./runtime-hardening-baseline.md)

