# 🔗 Phase 1 — Step 7: Playlist-Song Relationship Tests

## 📌 Context

After standalone CRUD stabilization for songs and playlists, the next confidence target is many-to-many relationship behavior.

## 🎯 Scope decision

Relationship tests cover:

- add song to playlist
- remove song from playlist
- relation visibility in playlist response
- missing song/playlist handling
- duplicate/conflicting relation behavior
- replacement behavior through `song_ids` update

## ✅ Implementation

Added:

- `tests/test_playlist_song_contract.py`

Behavior covered:

- valid link creation reflected in playlist representation
- duplicate link request does not duplicate relation
- valid unlink behavior
- repeated unlink remains controlled (idempotent `204`)
- missing playlist/song handling for link and unlink routes (`404`)
- playlist `PATCH` with `song_ids` replaces previous links and deduplicates repeated ids

## 🔁 Validation

Commands executed:

```bash
./.venv/bin/python -m pytest -q tests/test_playlist_song_contract.py
./.venv/bin/python -m pytest -q tests/test_playlist_song_contract.py
./.venv/bin/python -m pytest -q tests
```

Results:

- relationship module run 1: `3 passed`
- relationship module run 2: `3 passed`
- full suite: `12 passed`

## 🐞 Step execution notes (issues)

- No blocking coding/runtime issue occurred.
- Relationship behavior is now covered with deterministic assertions in the isolated test environment.

## 🏁 Completion criteria

Step 7 is complete when relationship rules behave consistently and are protected by repeatable automated tests.
