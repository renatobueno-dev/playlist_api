# 🚫 Phase 1 — Step 8: High-Value Negative Tests

## 📌 Context

After positive contract coverage for health, songs, playlists, and playlist-song relationships, this step adds a small set of failure-path tests that protect the API contract without over-expanding test volume.

## 🎯 Scope decision

Negative coverage is intentionally limited to high-value failures:

- invalid field type
- missing required field
- nonexistent song id
- nonexistent playlist id
- invalid relationship payload/action identifiers

## ✅ Implementation

Updated:

- `tests/test_songs_contract.py`
- `tests/test_playlists_contract.py`
- `tests/test_playlist_song_contract.py`

Behavior added or explicitly reinforced:

- song creation rejects invalid field type (`title` as object) with `422`
- playlist patch rejects invalid relationship payload (`song_ids` containing non-positive id) with `422`
- playlist create and patch reject nonexistent `song_ids` with `404` and clear message
- relationship endpoints reject invalid path identifier types with `422`
- existing tests already cover missing required fields and nonexistent song/playlist resources

## 🔁 Validation

Commands executed:

```bash
pytest -q
python -m pytest -q
python3 -m pytest -q
./.venv/bin/python -m pytest -q
```

Results:

- final command in project virtualenv: `14 passed`

## 🐞 Step execution notes (issues)

- `pytest` was not available in shell PATH (`command not found`).
- `python` alias was not available in shell (`command not found`).
- system `python3` did not have `pytest` installed.
- resolution: used `./.venv/bin/python -m pytest -q` as the project-safe execution path.

## 🏁 Completion criteria

Step 8 is complete when the API contract rejects clearly wrong input and missing resources predictably, while the negative suite remains small, deterministic, and repeatable.
