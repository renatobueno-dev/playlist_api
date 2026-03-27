# Istio Readiness

> Pre-flight checklist confirming the cluster is ready for Istio traffic and security resources. Run through these steps before applying mesh manifests.

---

Confirms the cluster is ready to apply Istio traffic and security behaviour.

## 🎯 Objective

Validate the minimum prerequisites:

1. Minikube cluster is running and reachable.
2. Istio control plane is installed and healthy.
3. Target namespace is prepared for sidecar injection.
4. Application pods run with Istio sidecars.
5. Istio custom resources can be applied.

## 💻 Commands used

Cluster and context:

```bash
minikube status
kubectl config current-context
kubectl get nodes
```

Istio installation via Minikube addons:

```bash
minikube addons enable istio
minikube addons enable istio-provisioner
kubectl get ns istio-system
kubectl rollout status deployment/istiod -n istio-system --timeout=240s
kubectl rollout status deployment/istio-ingressgateway -n istio-system --timeout=240s
kubectl get pods -n istio-system
```

Namespace preparation and sidecar injection:

```bash
kubectl label namespace music-platform istio-injection=enabled --overwrite
kubectl rollout restart deployment/music-platform-api -n music-platform
kubectl rollout restart statefulset/music-platform-db -n music-platform
kubectl get pods -n music-platform -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{range .spec.containers[*]}{.name}{" "}{end}{"\n"}{end}'
```

Istio CRD applicability:

```bash
kubectl get crds | rg "istio.io"
kubectl apply -n music-platform -f - <<'EOF'
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: readiness-check
spec:
  hosts:
    - music-platform-api.music-platform.svc.cluster.local
  http:
    - route:
        - destination:
            host: music-platform-api.music-platform.svc.cluster.local
            port:
              number: 8000
EOF
kubectl delete virtualservice readiness-check -n music-platform
```

## ✅ Readiness outcome

Phase 1 is considered complete when all checks pass:

- `istiod` and `istio-ingressgateway` are `Running`.
- `music-platform` namespace has `istio-injection=enabled`.
- API and DB pods include `istio-proxy` (`2/2 Running`).
- Istio networking resources can be created successfully.

## 📝 Notes

- On this machine, Minikube warns that Istio prefers more resources (8GB RAM and 4 CPUs).
- Even with that warning, Phase 1 reached healthy status and traffic resources were accepted.

---

## 🔗 Related documents

- [Istio traffic management](./traffic.md)
- [Istio security](./security.md)
- [Setup guide](../SETUP.md)
