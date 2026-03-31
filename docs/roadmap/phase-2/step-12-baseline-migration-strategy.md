# 🧭 Phase 2 — Step 12: Define Baseline Migration Strategy

## 📌 Context

Step 11 defined ownership: schema evolution authority will move from startup `create_all()` to Alembic.

Status note:

- Step 15 later completed this transition by removing startup `create_all()` responsibility.

Before generating migration files, the project needs one explicit baseline strategy that explains what the **first tracked schema state** is.

## 🎯 Scope decision

Baseline strategy is defined as:

1. **Baseline revision purpose**
   - The first Alembic revision formalizes the schema that already exists in the project domain (`songs`, `playlists`, `playlist_songs`) with current constraints/defaults.

2. **First tracked schema state**
   - The first tracked state is the schema represented by current SQLAlchemy models at the migration-adoption point.
   - This baseline is not random history reconstruction; it is the intentional "from here onward" contract.

3. **Environment handling rule**
   - **Fresh databases:** run migrations from base to head to create schema.
   - **Existing databases already created by startup flow:** stamp baseline revision, then apply future revisions normally.

4. **Change-freeze rule during baseline capture**
   - Avoid model-structure changes while capturing baseline revision to prevent mixing "baseline capture" with "new feature schema deltas."

5. **Post-baseline evolution rule**
   - After baseline exists, every schema change must be migration-backed; startup `create_all()` cannot remain the long-term schema evolution mechanism.

## ✅ Implementation

This step introduces strategy and documentation only.

Updated:

- roadmap Phase 2 step file for baseline strategy
- project indexes and architecture/readme notes to reflect baseline decision

No Alembic files or commands were executed in this step.

## 🔁 Validation

Step 12 is considered valid when these questions have deterministic answers:

- What exactly is the first tracked schema state?
- How do fresh environments obtain schema?
- How do existing environments migrate without replaying initial creation unsafely?
- How do we prevent baseline + new schema changes from being mixed in one revision?

## 🐞 Step execution notes (issues)

- No blocking issue occurred.
- This step intentionally avoids tool execution; it defines policy first.

## 🏁 Completion criteria

Step 12 is complete when baseline migration strategy is explicit enough that Step 13 can add Alembic structure without ambiguity about what the first revision represents.
