# Istio Traffic Management

> Documents the Gateway and VirtualService resources that route external traffic into the mesh and the DestinationRule resilience baseline for in-cluster traffic.

---

Defines the external and internal request path through the Istio mesh.

## 🚀 Traffic path

External client request path:

1. Client reaches the Istio ingress gateway for host `playcatch.local`.
2. Port `80` only redirects HTTP traffic to HTTPS.
3. Port `443` terminates TLS using the configured Istio credential secret and hands the request to the `VirtualService`.
4. Istio `VirtualService` routes traffic to `music-platform-api.music-platform.svc.cluster.local:8000`.
5. Kubernetes `Service` forwards the request to the API pod (`api` container).

In-cluster request path:

1. Workload calls `music-platform-api.music-platform.svc.cluster.local:8000`.
2. Kubernetes Service load-balances to API pods.
3. Sidecar proxies (`istio-proxy`) enforce Istio traffic rules.

## 🧱 Kubernetes vs Istio responsibilities

- Kubernetes `Service` (`ClusterIP`): stable internal endpoint and pod discovery.
- Istio `Gateway`: ingress entry point into the mesh.
- Istio `VirtualService`: HTTP host/path routing policy.
- Istio `DestinationRule`: destination traffic policy inside the mesh.

## 📄 Applied manifests

Manifest file: `k8s/istio/traffic-management.yaml`

> ⚠️ This manifest uses `__NAMESPACE__`, `__ISTIO_HOST__`, `__ISTIO_TLS_SECRET__`, and `__API_SERVICE_HOST__` placeholders — it is never applied directly. Use `scripts/render-istio-manifests.sh` to interpolate environment values before applying. The repository uses one shared render/apply path for both Istio files. In CI/CD the workflow step `Apply Istio traffic and security policies` runs this automatically. For local apply: `./scripts/render-istio-manifests.sh | kubectl apply -n "${NAMESPACE}" -f -`

Resources applied:

- `Gateway/playcatch-gateway` — redirects HTTP on port 80 to HTTPS and terminates TLS for the `${ISTIO_HOST}` hostname on port 443.
- `VirtualService/playcatch-api-ingress` — routes matched traffic to the API service on port 8000.
- `DestinationRule/playcatch-api-resilience` — traffic policy for in-cluster calls to the API service (see section below).

## 🛡️ DestinationRule: resilience configuration

`DestinationRule/playcatch-api-resilience` defines the traffic policy applied to in-cluster calls to the API service:

| Setting | Value | Effect |
|---------|-------|--------|
| `tls.mode` | `ISTIO_MUTUAL` | mTLS required for all connections to this destination |
| `loadBalancer` | `LEAST_REQUEST` | Route new requests to the instance with fewest active requests |
| `connectionPool.tcp.maxConnections` | `100` | Maximum concurrent TCP connections |
| `connectionPool.tcp.connectTimeout` | `10s` | Connection timeout |
| `connectionPool.http.http1MaxPendingRequests` | `100` | Maximum queued HTTP/1.1 requests waiting for an upstream connection |
| `connectionPool.http.maxRequestsPerConnection` | `100` | Recycle each upstream connection after 100 requests |
| `connectionPool.http.maxRetries` | `3` | Maximum HTTP retries per request |
| `connectionPool.http.idleTimeout` | `30s` | Drop idle connections after 30 seconds |
| `outlierDetection.consecutive5xxErrors` | `5` | Eject a pod after 5 consecutive 5xx errors |
| `outlierDetection.interval` | `10s` | Evaluation window for outlier detection |
| `outlierDetection.baseEjectionTime` | `30s` | Minimum ejection duration |
| `outlierDetection.maxEjectionPercent` | `50` | Cap: at most half the pods can be ejected at once |

**Why this matters:** without a `DestinationRule`, Istio uses default round-robin load balancing with no retry or circuit-breaking behaviour. This rule adds resilience without any application code change.

## ✅ Quick validation

```bash
kubectl get gateway,virtualservice,destinationrule -n music-platform
kubectl port-forward -n istio-system svc/istio-ingressgateway 18443:443
curl -k --resolve playcatch.local:18443:127.0.0.1 https://playcatch.local:18443/health
```

Expected:

- HTTPS requests for `playcatch.local` return the API response.
- Port `80` is a redirect entrypoint; direct HTTP validation should not be treated as the final application path.

---

## 🔗 Related documents

- [Istio readiness](./readiness.md)
- [Istio security](./security.md)
- [Infrastructure decisions](../INFRA_DECISIONS.md)
