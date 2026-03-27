# Post-Step Follow-ups

> Small corrections applied after Steps 1–6 were closed. Each item documents what was missed, the fix applied, and why it belongs to a specific earlier step.

---

Tracks small remaining fixes that should have been completed during earlier steps but were missed and then corrected afterward.

## 🔧 Missed in Step 5: Terraform provider patch-level constraint

What was missed:

- Step 5 should have locked provider policy at patch-level.
- Constraint remained at `~> 2.38`, allowing patch drift within the minor line.

Follow-up fix applied:

- `terraform/versions.tf`: `~> 2.38` -> `~> 2.38.0`
- `terraform/.terraform.lock.hcl`: constraints updated to `~> 2.38.0`

Why this belongs to Step 5:

- Step 5 scope was Terraform/Kubernetes posture hardening.
- Provider constraint precision is part of Terraform posture quality.

Validation:

```bash
terraform -chdir=terraform providers lock
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
```

## 🔧 Missed in Step 3: Startup retry vars in `.env.example`

What was missed:

- Step 3 hardened runtime behavior, but `.env.example` still did not expose startup retry tuning variables that already existed in code.

Follow-up fix applied:

- `.env.example` now includes:
  - `STARTUP_DB_MAX_RETRIES=20`
  - `STARTUP_DB_RETRY_SECONDS=2`

Why this belongs to Step 3:

- Step 3 scope included runtime hardening and startup behavior clarity.
- Environment template completeness is part of runtime configuration hardening.

Validation:

```bash
rg "STARTUP_DB_MAX_RETRIES|STARTUP_DB_RETRY_SECONDS" .env.example app/main.py
```

---

## 🔗 Related documents

- [Loose ends roadmap](./loose-ends-priority-roadmap.md)
- [Terraform posture hardening](./terraform-kubernetes-posture-hardening.md)
- [Runtime hardening](./runtime-hardening-baseline.md)
