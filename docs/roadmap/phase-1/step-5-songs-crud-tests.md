# 🎵 Phase 1 — Step 5: Songs CRUD Tests

## 📌 Context

After validating the smallest green slice (`/` and `/health`), the next target is the simplest business resource: songs.

## 🎯 Scope decision

Songs tests cover:

- create
- list
- get by id
- update
- delete
- missing id behavior
- invalid payload behavior

## ✅ Implementation

Added:

- `tests/test_songs_contract.py`

Behavior covered:

- valid creation and returned fields
- created song visibility in list endpoint
- record consistency on get-by-id
- partial update affecting only requested fields
- delete followed by not-found behavior
- missing id behavior for get/patch/delete
- payload validation failures (`422`) for missing required field and invalid duration

## 🔁 Validation

Commands executed:

```bash
./.venv/bin/python -m pytest -q tests/test_songs_contract.py
./.venv/bin/python -m pytest -q tests/test_songs_contract.py
./.venv/bin/python -m pytest -q tests
```

Results:

- songs contract run 1: `3 passed`
- songs contract run 2: `3 passed`
- full suite: `6 passed`

## 🐞 Step execution notes (issues)

- No blocking coding/runtime issue occurred.
- Songs behavior is stable across repeated runs in the isolated test environment.

## 🏁 Completion criteria

Step 5 is complete when songs CRUD behavior is reliable and predictable across repeated executions.
