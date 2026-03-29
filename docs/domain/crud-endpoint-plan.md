# CRUD Endpoint Plan

> CRUD route planning artifact for the Song and Playlist resources. For the stable API reference guide, see [API.md](../API.md).

---

This document defines the complete CRUD route map before implementing the missing endpoints.

## 🎵 Resource: Song

| Operation | Method | Path | Request Schema | Response Schema | Success Status | Error Status |
| --- | --- | --- | --- | --- | --- | --- |
| Create song | `POST` | `/songs/` | `SongCreate` | `SongRead` | `201` | `422` |
| List songs | `GET` | `/songs/` | - | `list[SongRead]` | `200` | - |
| Get song by id | `GET` | `/songs/{song_id}` | - | `SongRead` | `200` | `404` |
| Update song | `PATCH` | `/songs/{song_id}` | `SongUpdate` | `SongRead` | `200` | `404`, `422` |
| Delete song | `DELETE` | `/songs/{song_id}` | - | - | `204` | `404` |

## 📋 Resource: Playlist

| Operation | Method | Path | Request Schema | Response Schema | Success Status | Error Status |
| --- | --- | --- | --- | --- | --- | --- |
| Create playlist | `POST` | `/playlists/` | `PlaylistCreate` | `PlaylistRead` | `201` | `404`, `422` |
| List playlists | `GET` | `/playlists/` | - | `list[PlaylistRead]` | `200` | - |
| Get playlist by id | `GET` | `/playlists/{playlist_id}` | - | `PlaylistRead` | `200` | `404` |
| Update playlist | `PATCH` | `/playlists/{playlist_id}` | `PlaylistUpdate` | `PlaylistRead` | `200` | `404`, `422` |
| Delete playlist | `DELETE` | `/playlists/{playlist_id}` | - | - | `204` | `404` |

## ❓ Why `PATCH` for updates

`SongUpdate` and `PlaylistUpdate` are partial-update schemas (all fields optional), so `PATCH` matches the contract better than `PUT`.

## 🔢 Implementation order

1. Add service functions for `get_by_id`, `update`, and `delete` in `song_service.py`.
2. Add the new song routes in `routes/songs.py`.
3. Repeat the same for playlists in `playlist_service.py` and `routes/playlists.py`.
4. Re-run manual API checks in `/docs`.
5. Add tests (next stage) for success and `404` cases.

## 🔗 Relationship endpoints (Step 6 extension)

| Operation | Method | Path | Response Schema | Success Status | Error Status |
| --- | --- | --- | --- | --- | --- |
| Add song to playlist | `POST` | `/playlists/{playlist_id}/songs/{song_id}` | `PlaylistRead` | `201` | `404` |
| Remove song from playlist | `DELETE` | `/playlists/{playlist_id}/songs/{song_id}` | — | `204` | `404` |

`POST` returns the full updated `PlaylistRead` object — including the complete `songs` list after the operation. This means the caller always sees the resulting playlist state without needing a separate `GET` request. `DELETE` returns no body (`204 No Content`) and is idempotent — a second call returns `204` even if the link no longer exists.

---

## 🔗 Related documents

- [API reference](../API.md)
- [Domain scope](./domain-scope.md)
- [Architecture decisions](../ARCHITECTURE.md)
