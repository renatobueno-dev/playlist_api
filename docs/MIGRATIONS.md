# Migration Workflow — Music Platform API

This guide defines the migration lifecycle for this repository.

> Use this file as the operational source of truth for schema evolution.

---

## 🎯 Purpose

Alembic migration files are the single source of truth for database schema evolution.

Application startup validates:

- database reachability
- required table presence

Application startup does **not** create or mutate schema.

---

## 🧱 Schema ownership

- **Owner:** Alembic revisions in `migrations/versions/`
- **Runtime role:** validation only (`app/main.py`)
- **Rule:** any schema change must be tracked by a migration revision

Schema change examples that require a new migration:

- create/drop table
- add/remove column
- change type/default/nullability
- add/remove index or unique constraint
- add/remove foreign key or relationship persistence structure

Changes that do not require migration:

- pure Python refactor with no persisted schema impact
- API-only contract changes that do not alter tables/columns/constraints

---

## 🗂️ Baseline and existing databases

- Baseline revision id: `abff2336451a`
- Baseline message: `baseline schema`

For environments with a fresh database:

```bash
DATABASE_URL=<your-db-url> ./.venv/bin/alembic upgrade head
```

For databases created before migration adoption:

1. confirm live schema matches the baseline model contract
2. stamp baseline once
3. apply future upgrades normally

```bash
DATABASE_URL=<your-db-url> ./.venv/bin/alembic stamp abff2336451a
DATABASE_URL=<your-db-url> ./.venv/bin/alembic upgrade head
```

---

## 🔄 Standard migration flow (local development)

1. export `DATABASE_URL`
2. create migration when schema-relevant model changes occur
3. review generated revision
4. apply migration
5. run tests

```bash
export DATABASE_URL=sqlite:///./music.db
./.venv/bin/alembic revision --autogenerate -m "describe schema change"
./.venv/bin/alembic upgrade head
./.venv/bin/python -m pytest -q tests
```

---

## 🚀 Environment flow differences

| Environment | Who applies migrations | Expected workflow |
| --- | --- | --- |
| Local dev | Developer | Run `alembic upgrade head` before starting `uvicorn` |
| Docker Compose | Developer/operator | Start DB service, run migrations from host venv, then start API service |
| Kubernetes/Helm | Operator/release flow | Apply migrations separately (pre-deploy or release step) before expecting healthy API rollout |
| GitHub Actions deploy | Current workflow | Deploy workflow does **not** run Alembic automatically |

---

## ⚠️ Deployment note

Current CI/CD deploy (`.github/workflows/deploy.yml`) deploys infrastructure and workloads, but does not execute:

```bash
alembic upgrade head
```

Deployment automation assumes target database schema is already migrated to expected revision.

---

## 🧪 Verification commands

Check current revision:

```bash
DATABASE_URL=<your-db-url> ./.venv/bin/alembic current
```

Check migration history:

```bash
DATABASE_URL=<your-db-url> ./.venv/bin/alembic history --verbose
```

Dry-run SQL preview (optional):

```bash
DATABASE_URL=<your-db-url> ./.venv/bin/alembic upgrade head --sql
```

---

## 🐛 Failure signals

Common symptoms of missing migrations:

- startup error: required tables missing
- API pods restart loop after deployment
- runtime SQL errors for missing relations/columns

First check:

```bash
DATABASE_URL=<your-db-url> ./.venv/bin/alembic current
DATABASE_URL=<your-db-url> ./.venv/bin/alembic upgrade head
```

---

## 🔗 Related documents

- [Setup guide](./SETUP.md)
- [Architecture decisions](./ARCHITECTURE.md)
- [Kubernetes Helm guide](./kubernetes/helm-guide.md)
- [GitHub Actions workflow guide](./cicd/github-actions.md)
- [Migration folder reference](../migrations/README.md)
