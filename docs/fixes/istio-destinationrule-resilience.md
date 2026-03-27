# Step 6 Fix: Istio DestinationRule Resilience Baseline

> Adds a `DestinationRule` to upgrade Istio traffic posture from “present and secure” to “secure and more resilient” using conservative connection pool and outlier detection defaults.

---

## 🐛 Problem

Istio traffic resources already provided ingress and routing (`Gateway` + `VirtualService`), but there was no `DestinationRule` in project manifests.

Without `DestinationRule`, mesh traffic policy behavior depends on implicit defaults, reducing resilience control.

## 🎯 Goal

Upgrade Istio traffic posture from "present and secure" to "present, secure, and more resilient" using conservative defaults.

## 🔧 Implementation

### Added DestinationRule

File:

- `k8s/istio/traffic-management.yaml`

Resource:

- `DestinationRule/playcatch-api-resilience`

Host binding:

- Uses templated host `__API_SERVICE_HOST__` to stay aligned with namespace/render pipeline.

Traffic policy baseline:

- `tls.mode: ISTIO_MUTUAL`
- `loadBalancer.simple: LEAST_REQUEST`
- `connectionPool`:
  - TCP: `maxConnections: 100`, `connectTimeout: 10s`
  - HTTP: `http1MaxPendingRequests: 100`, `maxRequestsPerConnection: 100`, `maxRetries: 3`, `idleTimeout: 30s`
- `outlierDetection`:
  - `consecutive5xxErrors: 5`
  - `interval: 10s`
  - `baseEjectionTime: 30s`
  - `maxEjectionPercent: 50`

Reason:

- Adds explicit mesh behavior for load distribution, connection pressure handling, and unhealthy endpoint ejection.
- Keeps policy conservative enough for checkpoint scope while still providing real resilience controls.

## ✅ Validation

Commands:

```bash
./scripts/render-istio-manifests.sh >/tmp/istio-step6.yaml
rg "kind: DestinationRule|playcatch-api-resilience|ISTIO_MUTUAL|outlierDetection|connectionPool" /tmp/istio-step6.yaml
rg "__NAMESPACE__|__API_SERVICE_HOST__|__ISTIO_HOST__|__CLUSTER_DOMAIN__|__API_SERVICE_ACCOUNT__" /tmp/istio-step6.yaml
```

Checks:

- Rendered output contains `DestinationRule/playcatch-api-resilience`.
- Rendered output contains expected resilience policy keys.
- No unresolved template placeholders remain.

---

## 🔗 Related documents

- [Loose ends roadmap](./loose-ends-priority-roadmap.md)
- [Istio traffic management](../istio/traffic.md)
- [Istio security](../istio/security.md)

