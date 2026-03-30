# 🧪 Phase 1 — Step 1: Minimum API Test Scope

## 📌 Context

The current baseline still marks tests as under development in `README.md` and `docs/QUALITY.md`.
The validation workflow in `.github/workflows/deploy.yml` currently focuses on build and infrastructure checks.

## 🎯 Scope decision

The first automated test surface is limited to:

1. app availability (`GET /`)
2. health endpoint (`GET /health`)
3. songs CRUD behavior
4. playlists CRUD behavior
5. playlist-song link and unlink behavior
6. key invalid API contract paths

## ✅ Behaviors to validate

### 💚 App and health

- App starts and responds on root endpoint.
- Health endpoint returns successful status payload.

### 🎵 Songs

- Create, list, get by id, update, and delete.
- Missing `song_id` returns expected not-found behavior.
- Invalid payload is rejected by schema validation.

### 📚 Playlists

- Create, list, get by id, update, and delete.
- Missing `playlist_id` returns expected not-found behavior.
- Invalid payload is rejected by schema validation.

### 🔗 Playlist-song relationship

- Link an existing song to an existing playlist.
- Unlink an existing song from an existing playlist.
- Missing song or playlist is handled with expected error behavior.

### ⚠️ Key invalid cases (initial set)

- Missing required fields in create payloads.
- Invalid field types in payload.
- Non-existent song id in song/relationship routes.
- Non-existent playlist id in playlist/relationship routes.

## 🚫 Out of scope in Step 1

- Docker tests
- Kubernetes tests
- Istio tests
- GitHub Actions workflow behavior tests

## 🏁 Completion criteria

Step 1 is complete when this scope is written and used as the boundary for initial test implementation.

## 📝 Step execution notes

- Step rerun completed in this cycle.
- No coding/runtime issues were observed in this scope-definition step.
