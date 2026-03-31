# 🧱 Phase 2 — Step 11: Define Migration Ownership

## 📌 Context

Phase 1 introduced reliable behavior tests and CI coverage.  
Before introducing Alembic commands or files, schema ownership must be defined to avoid running two conflicting evolution models in parallel.

Status note:

- this document captures the decision point before Step 15 removed startup schema mutation
- current runtime behavior after Step 15 is migration-first (startup validates schema; it does not create tables)

Runtime behavior at Step 11 decision time:

- application startup still executes `Base.metadata.create_all()`
- Alembic migration history is not yet present

## 🎯 Scope decision

Migration ownership is defined as follows:

1. **Target owner (after adoption):** Alembic owns schema evolution history.
2. **Current owner (temporary):** startup `create_all()` remains a transitional bootstrap only.
3. **Transition rule:** startup schema creation must be reduced after baseline migrations are introduced (Phase 2 later steps).
4. **Single source of truth rule:** once migration flow is active, schema changes are applied through migration scripts, not implicit startup behavior.

Boundary of responsibility:

- **Alembic-owned:** table structure, constraints, indexes, and tracked schema evolution.
- **Application startup-owned (temporary only):** early bootstrap while migration baseline is being introduced.
- **Test harness-owned:** isolated test setup can continue resetting schema in test fixtures for deterministic runs.

## ✅ Implementation

This step intentionally changes **documentation/design ownership only**.

Updated:

- `README.md`
- `docs/ARCHITECTURE.md`
- roadmap indexes for Phase 2 tracking

No Alembic tooling or schema commands were introduced in this step.

## 🔁 Validation

Validation criteria for Step 11 are conceptual/documentary:

- ownership model is explicit and non-ambiguous
- transitional state and target state are both documented
- next migration steps can be executed without ownership confusion

## 🐞 Step execution notes (issues)

- No blocking issue occurred.
- This step intentionally avoids tool-level actions to prevent premature migration setup.

## 🏁 Completion criteria

Step 11 is complete when the team can clearly explain:

- what currently owns schema initialization,
- what will own schema evolution after migration adoption,
- and why startup-driven implicit schema evolution must be phased out.
