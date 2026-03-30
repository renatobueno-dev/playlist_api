# 🧪 Phase 1 — Step 4: Smallest Green Slice

## 📌 Context

Before CRUD coverage, the first reliable signal should come from the simplest API behavior:
root endpoint and health endpoint.

## 🎯 Scope decision

This step validates only:

- `GET /`
- `GET /health`

No CRUD tests are included in this step.

## ✅ Implementation

Added:

- `tests/test_health_contract.py`

Test coverage in this file:

- root message contract
- health status contract

## 🔁 Validation

Commands executed:

```bash
./.venv/bin/python -m pytest -q tests/test_health_contract.py
./.venv/bin/python -m pytest -q tests/test_health_contract.py
./.venv/bin/python -m pytest -q tests/test_health_contract.py
```

Results:

- run 1: `2 passed`
- run 2: `2 passed`
- run 3: `2 passed`

## 🐞 Step execution notes (issues)

- No blocking coding/runtime issue occurred.
- The test runner, app instantiation, and basic request flow are stable for the smallest slice.

## 🏁 Completion criteria

Step 4 is complete when root and health tests pass reliably across repeated runs.
