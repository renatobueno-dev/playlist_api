# Stage 3 - Helm Chart Structure (Phase 3)

This phase organizes Kubernetes deployment into a reusable Helm chart.

## Chart location

`helm/music-platform`

## Chart structure

```text
helm/music-platform/
├── .helmignore
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── NOTES.txt
    ├── api-deployment.yaml
    ├── api-service.yaml
    ├── configmap.yaml
    ├── db-service.yaml
    ├── db-statefulset.yaml
    └── secret.yaml
```

## What each part does

- `Chart.yaml`: chart metadata and versioning.
- `values.yaml`: central place for configurable parameters.
- `templates/_helpers.tpl`: shared naming and label helpers.
- `templates/api-*.yaml`: API runtime and service exposure.
- `templates/db-*.yaml`: PostgreSQL runtime and service identity.
- `templates/configmap.yaml`: non-sensitive DB configuration.
- `templates/secret.yaml`: sensitive values, including `DATABASE_URL`.
- `templates/NOTES.txt`: post-install access instructions.

## Main configurable values

- API image repo/tag/pull policy.
- API replica count and service type/port.
- DB image repo/tag/pull policy.
- DB name/user/password.
- DB persistence toggle, storage size, and optional storage class.

## Validate chart locally

Install Helm if needed:

```bash
brew install helm
```

Lint and render:

```bash
helm lint helm/music-platform
helm template music-platform helm/music-platform
```

## Install to Minikube

```bash
minikube image load music-platform-api:latest
helm upgrade --install music-platform helm/music-platform --namespace music-platform --create-namespace
kubectl get all -n music-platform
kubectl port-forward svc/music-platform-api 8000:8000 -n music-platform
```

Open:
- `http://127.0.0.1:8000/docs`

If your API image uses a different tag, update either:
- `helm/music-platform/values.yaml` (`api.image.tag`), or
- command line override:
  - `helm upgrade --install ... --set api.image.tag=<tag>`
