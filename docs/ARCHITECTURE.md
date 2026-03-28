# Architecture Decisions — Music Platform API

> Single reference for design decisions made in this project.
> See [README.md](../README.md) for setup and usage. See [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md) for the development narrative.

---

## 🗄️ Data Model

```
Song ──────────────────────────────────────┐
                                           │  (via playlist_songs)
Playlist ─────────────────────────────────┘
```

The many-to-many association table `playlist_songs` carries `added_at` — recording when a song was linked. A pure join table without metadata would lose information for free.

### Song fields

| Field              | Type     | Constraints                      |
|--------------------|----------|----------------------------------|
| `id`               | int      | primary key, indexed              |
| `title`            | string   | max 255, required                 |
| `artist`           | string   | max 255, required                 |
| `album`            | string   | max 255, optional                 |
| `genre`            | string   | max 100, optional                 |
| `duration_seconds` | int      | ≥ 1 (Pydantic), optional         |
| `release_date`     | date     | optional                          |
| `release_year`     | int      | 1800–2100, optional               |
| `created_at`       | datetime | server default, read-only         |

### Playlist fields

| Field         | Type     | Constraints                      |
|---------------|----------|----------------------------------|
| `id`          | int      | primary key, indexed              |
| `name`        | string   | max 255, required                 |
| `description` | string   | max 500, optional                 |
| `is_public`   | bool     | default `True`                    |
| `created_at`  | datetime | server default, read-only         |
| `updated_at`  | datetime | server default + onupdate         |

### playlist_songs fields

| Field         | Type     | Constraints                      |
|---------------|----------|----------------------------------|
| `playlist_id` | int FK   | cascade delete                   |
| `song_id`     | int FK   | cascade delete                   |
| `added_at`    | datetime | server default, read-only         |

---

## 🏗️ Layer Structure

```
routes → schemas → services → models → database
```

| Layer      | File location       | Responsibility                                      |
|------------|---------------------|-----------------------------------------------------|
| `routes/`  | `app/routes/`       | HTTP handling, dependency injection, status codes   |
| `schemas/` | `app/schemas/`      | Pydantic validation, input/output contracts         |
| `services/`| `app/services/`     | Business logic, database operations                 |
| `models/`  | `app/models/`       | SQLAlchemy ORM definitions                          |
| `database` | `app/database.py`   | Engine, session factory, `get_session()` dependency |

The `services/` separation is intentional: without it, routes accumulate database logic and tests become tightly coupled to HTTP layer details.

---

## 📐 Schema Design Decisions

### `PATCH` not `PUT` for updates

`SongUpdate` and `PlaylistUpdate` are partial schemas — all fields are optional. `PATCH` is semantically correct for partial updates. Using `PUT` with a partial schema would allow silent data loss (fields omitted would be treated as intentionally cleared).

### `extra="forbid"` on all input schemas

All `Create` and `Update` schemas use `model_config = ConfigDict(extra="forbid")`. This prevents undocumented fields from silently passing through, making the API contract explicit.

### `song_ids` behaviour in playlists

`song_ids` in `PlaylistCreate` defaults to an empty list — a playlist can be created empty and songs added later via the link endpoints. In `PlaylistUpdate`, `song_ids` is `None` by default:
- if **omitted**: existing song links are preserved
- if **provided**: links are replaced with the new set

Silent replacement of existing links without explicit intent would be destructive. The `exclude_unset=True` in the service layer enforces this distinction.

### Duplicate `song_ids` are deduplicated

`_deduplicate_ids()` in `playlist_service.py` removes duplicates while preserving input order before resolving songs. This prevents the same song appearing twice in a playlist due to a client-side mistake.

---

## 🗃️ Database Decisions

### SQLite support in local development

`app/database.py` requires `DATABASE_URL` to be set — it raises `RuntimeError` if the variable is missing. For local development without PostgreSQL, set `DATABASE_URL=sqlite:///./music.db`. Docker Compose and Kubernetes always inject a PostgreSQL `DATABASE_URL`.

### `check_same_thread` for SQLite only

`connect_args={"check_same_thread": False}` is applied only when the URL starts with `sqlite`. This is necessary for SQLAlchemy's sync driver in FastAPI's threaded request handling.

### No Alembic — `create_all` only

Schema is initialised via `Base.metadata.create_all()`. Alembic migration tracking is under development.

---

## ⚙️ Service Layer Decisions

### `selectinload` for playlist queries

All playlist queries use `.options(selectinload(Playlist.songs))` to eagerly load the songs relationship in a separate query. This avoids N+1 query patterns when serialising playlists that include their song list.

### `MissingSongsError` custom exception

A domain-specific exception was created instead of returning `None` or raising a generic `ValueError`. This separates business-rule violations from unexpected runtime errors, and allows routes to map the error to a precise `404` response with the list of missing IDs.

---

## 🚀 Startup Resilience

`main.py` retries `Base.metadata.create_all()` on startup with configurable attempts and delay:

| Variable                  | Default | Purpose                              |
|---------------------------|---------|--------------------------------------|
| `STARTUP_DB_MAX_RETRIES`  | `20`    | Maximum connection attempts          |
| `STARTUP_DB_RETRY_SECONDS`| `2`     | Wait between attempts (seconds)      |

`depends_on: condition: service_healthy` in Docker Compose reduces the race window but does not fully eliminate it — the retry loop is the final safety net. In Kubernetes, startup behaviour is also governed by Helm probe values (`api.probes.startup` in `values.yaml`).

---

> For Kubernetes, Istio, Terraform, and CI/CD design decisions, see [INFRA_DECISIONS.md](./INFRA_DECISIONS.md).

---

## 🔗 Related documents

- [Domain scope and endpoint plan](./domain/domain-scope.md)
- [INFRA_DECISIONS.md](./INFRA_DECISIONS.md)
- [Kubernetes concept map](./kubernetes/k8s-concept-map.md)
- [Development Log](./DEVELOPMENT_LOG.md)
