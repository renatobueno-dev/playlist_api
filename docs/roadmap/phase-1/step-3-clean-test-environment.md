# 🧪 Phase 1 — Step 3: Clean Test Environment

## 📌 Context

Before adding functional API tests, the project needs a dedicated test runtime that does not depend on local manual data or default app startup path.

## 🎯 Scope decision

Test execution is isolated from normal runtime by introducing:

- dedicated test dependency file (`requirements-dev.txt`)
- dedicated test harness (`tests/conftest.py`)
- disposable SQLite test database path per test run
- database reset fixture for deterministic test state

## ✅ Implementation

### Added files

- `requirements-dev.txt`
- `tests/conftest.py`
- `tests/test_environment_setup.py`

### Isolation behavior

- `DATABASE_URL` is forced to a temporary SQLite path created for the test run.
- startup retry environment is tuned for tests (`STARTUP_DB_MAX_RETRIES=1`, `STARTUP_DB_RETRY_SECONDS=0`).
- schema is reset before each test (`drop_all` + `create_all`).
- temporary test directory is removed at end of session.

## 🔁 Validation

Commands executed:

```bash
./.venv/bin/python -m pip install -r requirements-dev.txt
./.venv/bin/python -m pytest -q tests/test_environment_setup.py
./.venv/bin/python -m pytest -q tests/test_environment_setup.py
./.venv/bin/python -m pytest -q tests/test_environment_setup.py
```

Results:

- dependencies installed from `requirements-dev.txt` (already satisfied in current environment)
- repeated runs passed: `1 passed` in all three executions

## 🐞 Step execution notes (issues)

- No blocking coding/runtime issue occurred.
- One expected setup observation: there were no existing `tests/` files in the repository at this restart point, so the Step 3 harness and environment smoke test were created from scratch.

## 🏁 Completion criteria

Step 3 is complete when tests can run repeatedly with isolated and disposable state, without relying on local development database state.
