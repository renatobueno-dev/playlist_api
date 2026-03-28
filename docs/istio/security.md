# Istio Security

> Defines mTLS enforcement and access control policies for the `music-platform` namespace. Maps precisely which sources can reach the API and DB workloads.

---

Defines mTLS enforcement and access control policies after traffic routing is established.

## 🔐 Security model

Trusted traffic:

- Ingress traffic from Istio control plane namespace (`istio-system`) to API on port `8000`.
- In-namespace service traffic (`music-platform`) to API on port `8000`.
- API workload identity (`music-platform-api-sa`) to DB on port `5432`.

Restricted traffic:

- Any non-mTLS traffic into workloads in `music-platform`.
- Any source other than API service account trying to access DB `5432`.
- Any source outside trusted namespaces trying to access API `8000`.

## 📜 Implemented resources

Manifest file: `k8s/istio/security-policies.yaml`

> ⚠️ This manifest uses `__NAMESPACE__`, `__API_SERVICE_ACCOUNT__`, and `__CLUSTER_DOMAIN__` placeholders — it is never applied directly. Use `scripts/render-istio-manifests.sh` to interpolate environment values before applying. In CI/CD the workflow step `Apply Istio traffic and security policies` runs this automatically. For local apply: `./scripts/render-istio-manifests.sh | kubectl apply -n music-platform -f -`

Resources:

1. `PeerAuthentication/music-platform-strict-mtls`
   - Enforces `STRICT` mTLS in namespace `music-platform`.
2. `AuthorizationPolicy/api-allow-trusted-sources`
   - Allows API access only from trusted namespaces on port `8000`.
3. `AuthorizationPolicy/db-allow-api-only`
   - Allows DB access only from principal `cluster.local/ns/music-platform/sa/music-platform-api-sa` on port `5432`.

## 💪 Identity hardening in Helm

To support identity-based policy, dedicated service accounts are used:

- API: `music-platform-api-sa`
- DB: `music-platform-db-sa`

Helm templates updated:

- `helm/music-platform/templates/serviceaccounts.yaml`
- `helm/music-platform/templates/api-deployment.yaml`
- `helm/music-platform/templates/db-statefulset.yaml`
- `helm/music-platform/templates/_helpers.tpl`

## ✅ Apply and verify

```bash
helm upgrade --install music-platform helm/music-platform --namespace music-platform --create-namespace
./scripts/render-istio-manifests.sh | kubectl apply -n music-platform -f -
kubectl get peerauthentication,authorizationpolicy -n music-platform
```

Optional checks:

- Confirm service accounts:
  - `kubectl get sa -n music-platform`
- Confirm pod identities:
  - `kubectl get pod -n music-platform <pod-name> -o jsonpath='{.spec.serviceAccountName}'`
- Confirm API still reachable via ingress host:
  - `curl -H "Host: playcatch.local" http://127.0.0.1:18080/health`

---

## 🔗 Related documents

- [Istio traffic management](./traffic.md)
- [Istio readiness](./readiness.md)
- [Helm guide](../kubernetes/helm-guide.md)
