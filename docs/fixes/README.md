# Fixes Documentation

> Post-checkpoint remediation record. Each file documents one confirmed loose end that was closed: the problem, the goal, implementation details, and validation commands. Separate from stage documentation by design.

---

This folder records completed post-checkpoint remediation work for confirmed repository loose ends.

It is intentionally separated from the original stage documentation and does not replace the existing `docs/` guides.

## 📄 Files

- `loose-ends-priority-roadmap.md`: historical remediation order, checkpoint lens, and execution record.
- `namespace-single-source-of-truth.md`: Step 1 implementation details for namespace consistency across Terraform, workflow, and Istio apply flow.
- `security-defaults-hardening.md`: Step 2 implementation details for Helm default image/secret hardening.
- `runtime-hardening-baseline.md`: Step 3 implementation details for Docker runtime and Helm resource hardening.
- `pipeline-reproducibility-hardening.md`: Step 4 implementation details for CI reproducibility and dependency/image pinning.
- `terraform-kubernetes-posture-hardening.md`: Step 5 implementation details for Terraform baseline posture and namespace security labels.
- `istio-destinationrule-resilience.md`: Step 6 implementation details for Istio DestinationRule resilience policy.
- `post-step-followups.md`: remaining small follow-up fixes completed after Steps 1-6.
