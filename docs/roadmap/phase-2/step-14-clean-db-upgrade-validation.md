# 🧪 Phase 2 — Step 14: Validate Clean-Database Upgrade Flow

## 📌 Context

Step 13 introduced the migration framework structure.  
This step proves the migration system is functional by running a real upgrade on a clean database and verifying resulting schema state.

## 🎯 Scope decision

Validation target for this step:

- baseline migration revision exists
- clean database can run `upgrade head` successfully
- expected domain tables are created from migration history
- Alembic version table is stamped to current head

## ✅ Implementation

Created baseline revision:

- `migrations/versions/abff2336451a_baseline_schema.py`

The baseline revision captures current domain schema:

- `songs`
- `playlists`
- `playlist_songs`

## 🔁 Validation

Commands executed:

```bash
rm -f step14_clean_upgrade.db
DATABASE_URL=sqlite:///./step14_clean_upgrade.db ./.venv/bin/alembic upgrade head
sqlite3 step14_clean_upgrade.db ".tables"
sqlite3 step14_clean_upgrade.db "SELECT version_num FROM alembic_version;"
```

Observed result:

- upgrade ran from base to `abff2336451a`
- tables present: `songs`, `playlists`, `playlist_songs`, `alembic_version`
- version stamp returned: `abff2336451a`

Regression safety check:

```bash
./.venv/bin/python -m pytest -q tests
```

Result:

- `14 passed`

## 🐞 Step execution notes (issues)

- No blocking issue occurred.
- Local Alembic CLI was available and baseline revision generation completed without manual edits.

## 🏁 Completion criteria

Step 14 is complete when a clean database can reconstruct expected schema state through migrations and lands on the current migration head revision.
