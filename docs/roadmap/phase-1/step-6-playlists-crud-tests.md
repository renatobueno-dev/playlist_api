# 📚 Phase 1 — Step 6: Playlists CRUD Tests

## 📌 Context

After songs CRUD stabilization, the next business resource is playlists.
This step focuses on playlists CRUD behavior alone, without relationship-complexity expansion.

## 🎯 Scope decision

Playlists tests cover:

- valid creation
- listing
- get by id
- partial update behavior
- delete
- missing id behavior
- invalid payload behavior

## ✅ Implementation

Added:

- `tests/test_playlists_contract.py`

Behavior covered:

- valid playlist creation and returned fields
- created playlist visibility in list endpoint
- record consistency on get-by-id
- partial update for selected fields, preserving unchanged fields
- delete followed by expected not-found behavior
- missing id behavior for get/patch/delete
- invalid payload handling (`422`) for missing required field, extra field, and invalid patch name

## 🔁 Validation

Commands executed:

```bash
./.venv/bin/python -m pytest -q tests/test_playlists_contract.py
./.venv/bin/python -m pytest -q tests/test_playlists_contract.py
./.venv/bin/python -m pytest -q tests
```

Results:

- playlists contract run 1: `3 passed`
- playlists contract run 2: `3 passed`
- full suite: `9 passed`

## 🐞 Step execution notes (issues)

- No blocking coding/runtime issue occurred.
- Playlist CRUD behavior is stable on its own in repeated executions.

## 🏁 Completion criteria

Step 6 is complete when playlist CRUD behavior is reliable and repeatable without relationship-heavy edge-case dependency.
