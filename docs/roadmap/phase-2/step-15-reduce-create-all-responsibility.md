# 🧭 Phase 2 — Step 15: Reduce `create_all()` Responsibility

## 📌 Context

After baseline migration and clean-upgrade validation, startup-driven schema mutation was the remaining ambiguity.

This step removes implicit startup schema creation so migration files are the only schema-evolution path.

## 🎯 Scope decision

Runtime startup behavior is now:

- retry DB connectivity
- validate required schema tables exist
- fail fast with migration guidance if schema is missing

Runtime startup no longer:

- creates tables
- mutates schema
- acts as schema evolution authority

## ✅ Implementation

Code changes:

- `app/main.py`
  - removed `Base.metadata.create_all()` startup usage
  - added `wait_for_database()` connectivity check
  - added `validate_required_schema()` required-table guard

Documentation updates:

- local and container setup now run migrations before API startup
- architecture notes now describe migration-owned schema evolution
- roadmap/readme indexes updated for Step 15

## 🔁 Validation

Commands executed:

```bash
./.venv/bin/python -m pytest -q tests
```

Result:

- `14 passed`

Validation intent:

- confirm startup behavior change does not break contract tests
- confirm project now has a single schema-evolution story

## 🐞 Step execution notes (issues)

- No blocking issue occurred.
- Existing docs that assumed automatic startup schema creation were updated to avoid contradictory guidance.

## 🏁 Completion criteria

Step 15 is complete when the project no longer communicates dual schema authority and startup schema mutation is replaced by migration-first workflow.
