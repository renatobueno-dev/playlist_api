# API Reference — Music Platform

> API version: **1.6.1** · Stable endpoint reference. For endpoint planning and implementation decisions, see [crud-endpoint-plan.md](./domain/crud-endpoint-plan.md).

---

## Base URL

When running locally: `http://localhost:8000`

---

## 🔧 Utility

| Method | Path | Description | Success |
| --- | --- | --- | --- |
| `GET` | `/` | API status message | `200` |
| `GET` | `/health` | Service health check | `200` |

---

## 🎵 Songs

| Operation | Method | Path | Request Schema | Response Schema | Success | Error |
| --- | --- | --- | --- | --- | --- | --- |
| List songs | `GET` | `/songs/` | — | `list[SongRead]` | `200` | — |
| Create song | `POST` | `/songs/` | `SongCreate` | `SongRead` | `201` | `422` |
| Get song | `GET` | `/songs/{song_id}` | — | `SongRead` | `200` | `404` |
| Update song | `PATCH` | `/songs/{song_id}` | `SongUpdate` | `SongRead` | `200` | `404`, `422` |
| Delete song | `DELETE` | `/songs/{song_id}` | — | — | `204` | `404` |

---

## 📋 Playlists

| Operation | Method | Path | Request Schema | Response Schema | Success | Error |
| --- | --- | --- | --- | --- | --- | --- |
| List playlists | `GET` | `/playlists/` | — | `list[PlaylistRead]` | `200` | — |
| Create playlist | `POST` | `/playlists/` | `PlaylistCreate` | `PlaylistRead` | `201` | `404`, `422` |
| Get playlist | `GET` | `/playlists/{playlist_id}` | — | `PlaylistRead` | `200` | `404` |
| Update playlist | `PATCH` | `/playlists/{playlist_id}` | `PlaylistUpdate` | `PlaylistRead` | `200` | `404`, `422` |
| Delete playlist | `DELETE` | `/playlists/{playlist_id}` | — | — | `204` | `404` |

---

## 🔗 Playlist–Song relationships

`POST` returns the full updated `PlaylistRead` object — the complete `songs` list reflects the state after the operation. `DELETE` returns no body.

| Operation | Method | Path | Response Schema | Success | Error |
| --- | --- | --- | --- | --- | --- |
| Add song to playlist | `POST` | `/playlists/{playlist_id}/songs/{song_id}` | `PlaylistRead` | `201` | `404` |
| Remove song from playlist | `DELETE` | `/playlists/{playlist_id}/songs/{song_id}` | — | `204` | `404` |

---

## 📌 Notes

- `SongUpdate` and `PlaylistUpdate` are **partial-update schemas** (all fields optional) — this is why `PATCH` is used instead of `PUT`.
- `PlaylistCreate` and `PlaylistUpdate` accept `song_ids: list[int]`. If provided, existing song links are **replaced**; if omitted, links are unchanged.
- Non-existent IDs return `404`.
- Interactive docs: `/docs` (Swagger UI) and `/redoc` (ReDoc) when the server is running.

---

## 🔗 Related documents

- [Domain scope](./domain/domain-scope.md)
- [CRUD endpoint plan (planning artifact)](./domain/crud-endpoint-plan.md)
- [Architecture decisions](./ARCHITECTURE.md)
