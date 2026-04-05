# Release Version Plan

> Living release/version plan for the post-`v1.8.0` cycle. Use this document to keep the release map, next patch scope, and later milestone boundaries in one place.

## 📌 Current release map

| Version  | Theme                          | Status                    |
| -------- | ------------------------------ | ------------------------- |
| `v1.8.0` | Quality/security/CI foundation | Tagged and pushed         |
| `v1.8.1` | Fix GHCR publish coupling      | Next patch                |
| `v1.9.0` | Trivy / container hardening    | Next minor                |
| `v2.0.0` | Auth + operational maturity    | Longer-horizon major step |

## 🩹 `v1.8.1` scope

`v1.8.1` is a patch release because it fixes broken CI/package publication behavior without changing the API contract or adding a new product feature.

### Goal

Make GHCR image publication work independently from Kubernetes deployment, and publish a semantic image tag for future release tags.

### Current problem

The current GitHub Actions workflow couples GHCR image publication to the same `KUBE_CONFIG_DATA` gate used for cluster deployment. When the deploy secret is absent, the workflow skips:

- Docker Buildx setup
- GHCR login
- image build/push
- cluster deploy steps

That leaves the package page stale even after a normal release.

### Precise implementation checklist

1. Update `.github/workflows/deploy.yml` triggers to support future release-tag publication.
   - Keep `pull_request`.
   - Keep `push.branches: [main]`.
   - Add `push.tags: ['v*']`.
   - Keep `workflow_dispatch`.
2. Introduce a dedicated `publish-image` job after the four validation jobs.
   - It should depend on `fast-quality`, `python-quality`, `security-validation`, and `runtime-validation`.
   - It should have `contents: read` and `packages: write`.
3. Move image publication steps out of `deploy` and into `publish-image`.
   - checkout repository
   - set up Docker Buildx
   - log in to GHCR
   - build and push the API image
4. Remove the `KUBE_CONFIG_DATA` dependency from image publication.
   - `publish-image` must not read `KUBE_CONFIG_DATA`.
   - missing deploy credentials must no longer block GHCR publication.
5. Keep `deploy` as the cluster-only job.
   - make it depend on `publish-image`
   - keep it restricted to `refs/heads/main`
   - keep the `KUBE_CONFIG_DATA` precheck only for deploy-specific steps
6. Add tag-aware image publishing rules.
   - on `push` to `main`, publish:
     - `${IMAGE_NAME}:${github.sha}`
     - `${IMAGE_NAME}:latest`
   - on `push` for `refs/tags/v*`, publish:
     - `${IMAGE_NAME}:${github.ref_name}`
     - optionally also `${IMAGE_NAME}:${github.sha}` if desired for traceability
7. Ensure release-tag pushes do not trigger a cluster deploy.
   - tag pushes should publish the container image only
   - deploy remains branch-based, not tag-based
8. Verify the resulting behavior with two checks.
   - push a normal commit to `main` and confirm `latest` plus SHA tag are published even if `KUBE_CONFIG_DATA` is unset
   - push a version tag like `v1.8.1` and confirm the semantic GHCR tag is published without running deploy

### Acceptance criteria

- A `push` to `main` publishes a fresh GHCR image even when `KUBE_CONFIG_DATA` is missing.
- A `push` of `v1.8.1` publishes `ghcr.io/<owner>/music-platform-api:v1.8.1`.
- Cluster deployment still runs only from `main`.
- Tag pushes never attempt cluster deployment.
- The public package page reflects the current release line instead of an older SHA-only image.

## 🛡️ `v1.9.0` scope

`v1.9.0` is the next security-focused minor release. It should stay tightly scoped to container and image hardening work:

- add `trivy config` for Dockerfile, Compose, Terraform, and Kubernetes/Helm inputs
- add `trivy image` for the published `music-platform-api` image
- decide whether PostgreSQL image CVEs are accepted with justification or must be hardened away
- record the DB runtime posture decision, including `readOnlyRootFilesystem` expectations if changed

## 🚀 `v2.0.0` scope

`v2.0.0` is the operational-maturity milestone anchored by authentication and authorization:

- add auth/authz to the API contract
- document the new runtime and secret expectations required for auth
- optionally bundle external secret-controller integration
- optionally bundle CI migration automation and production DNS/TLS work if they are part of the same operational boundary

Auth is the clearest SemVer-major anchor. The other items can move earlier if they stay non-breaking and are valuable on their own.
