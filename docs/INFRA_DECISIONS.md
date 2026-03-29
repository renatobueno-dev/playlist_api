# Infrastructure Decisions — Music Platform API

> Key reasoning behind Kubernetes, Istio, Terraform, and CI/CD choices. See [ARCHITECTURE.md](./ARCHITECTURE.md) for application-level (data model, schemas, services) decisions.

---

## ☸️ Kubernetes Decisions

### StatefulSet for PostgreSQL

`StatefulSet` was chosen over `Deployment` for the database workload. A `Deployment` could work in simple cases but `StatefulSet` provides stable pod identity and guaranteed PVC binding — the correct resource for stateful services that must preserve data across pod restarts.

### Three-probe strategy

Each pod uses three distinct probes with explicit roles:

| Probe           | Role                                                                   |
|-----------------|------------------------------------------------------------------------|
| `startupProbe`  | Gives the pod time to initialise before liveness kicks in              |
| `readinessProbe`| Controls when the pod receives traffic                                 |
| `livenessProbe` | Restarts the pod if the process becomes unresponsive                   |

Default values (`initialDelaySeconds: 5`, `failureThreshold: 30`, `periodSeconds: 2`) give up to ~65 seconds of grace — enough for Uvicorn startup plus database connection. Configured under `api.probes` in `helm/music-platform/values.yaml`.

Full chart reference: [`docs/kubernetes/helm-guide.md`](./kubernetes/helm-guide.md)

---

## 🕸️ Istio Decisions

### mTLS STRICT and ServiceAccount identity

`PeerAuthentication` enforces `STRICT` mTLS across the namespace. This rejects any non-mTLS traffic and requires dedicated `ServiceAccount` resources (`music-platform-api-sa`, `music-platform-db-sa`) so that `AuthorizationPolicy` rules can use principal identity rather than just namespace.

The practical consequence: Helm templates include `serviceaccounts.yaml`, referenced by both the `Deployment` and `StatefulSet` manifests.

### Gateway / VirtualService / Service distinction

The Kubernetes `Service` handles pod discovery only — no HTTP awareness. The Istio `Gateway` is the external entry point into the mesh; the `VirtualService` defines HTTP routing after entry. Full mapping and validation steps: [`docs/istio/traffic.md`](./istio/traffic.md) · [`docs/istio/security.md`](./istio/security.md)

### Istio manifest templating

Manifests in `k8s/istio/` use `__NAMESPACE__`, `__ISTIO_HOST__`, `__ISTIO_TLS_SECRET__`, `__API_SERVICE_HOST__`, `__CLUSTER_DOMAIN__`, and `__API_SERVICE_ACCOUNT__` placeholders and are rendered at deploy time via `scripts/render-istio-manifests.sh`. This keeps namespace, TLS, and service identity values consistent without duplicating them across files.

---

## 🏗️ Terraform Decisions

### Conservative dual-ownership scope

The primary risk of Terraform alongside Helm is dual ownership: if both manage the same Kubernetes object, `apply` runs conflict. The chosen scope is minimal and safe: Terraform owns the namespace plus the required baseline labels, including `istio-injection=enabled` and the Pod Security Standards `enforce`, `warn`, `audit`, and `*-version` labels. All workloads stay exclusively in Helm.

The full ownership matrix and anti-conflict rules are in [`docs/terraform/scope-and-boundary.md`](./terraform/scope-and-boundary.md). Minimum locked scope is documented in the same file.

### Namespace import before apply

If the namespace already exists in the cluster (created by a previous Helm deploy or manually), the CI/CD workflow imports it into Terraform state before running `apply`. Without the import, Terraform would attempt to create a resource that already exists and fail. See [`docs/terraform/flow-integration.md`](./terraform/flow-integration.md) for the full explanation.

---

## ⚙️ CI/CD Decisions

### Deploy guard by secret

The workflow skips cluster operations if `KUBE_CONFIG_DATA` is absent, emitting a `::notice::` instead of failing with an opaque auth error. This makes the workflow safe to run in forks or environments without a configured cluster.

### Pinned CLI versions

`kubectl`, `helm`, and `terraform` are installed at fixed versions in CI. Using `latest` means a silent tool update can break the pipeline without any code change, with no obvious error pointing to the tool version.

### Terraform binary collision fix

The project has a `terraform/` directory at the root. The default Terraform install script extracts the binary into the working directory, causing a directory name collision. The implemented fix extracts into a temporary directory and moves the binary to `/usr/local/bin`. Full troubleshooting case: [`docs/cicd/github-actions.md`](./cicd/github-actions.md).

---

## 🔗 Related documents

- [Application architecture decisions](./ARCHITECTURE.md)
- [Kubernetes concept map](./kubernetes/k8s-concept-map.md)
- [Helm guide](./kubernetes/helm-guide.md)
- [Istio traffic management](./istio/traffic.md)
- [Istio security](./istio/security.md)
- [Terraform integration flow](./terraform/flow-integration.md)
- [GitHub Actions guide](./cicd/github-actions.md)
