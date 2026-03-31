# Docker Workflow

> Steps A–C: building and validating the API image in isolation. For multi-service orchestration with Docker Compose (Steps D–E), see [compose-guide.md](./compose-guide.md).

---

Focuses on portability and reproducibility.
The target is not only "it works on my machine", but "it works the same way in containers."

## 🛠️ Prerequisites

- Docker Desktop (or Docker Engine + Compose) installed and running.
- Project root as current directory:
  - `.../13_checkpoint_nivel_3`

## 🅰️ Step A - Freeze startup logic

Use these values as the source of truth for container runtime:

| Item | Value |
| --- | --- |
| FastAPI entrypoint | `app.main:app` |
| Dependencies file | `requirements.txt` |
| API port (container) | `8000` |
| Runtime command | `uvicorn app.main:app --host 0.0.0.0 --port 8000` |

Checkpoint:
- All Docker/Compose files must respect these same values.

## 🅱️ Step B - Create Dockerfile (API only)

Goal:
- Build an API image that can run independently.

Commands:

> `DATABASE_URL` is always required. Startup now validates schema and does not create tables automatically, so migrations must be applied before starting API runtime.

```bash
DATABASE_URL=sqlite:///./stepb_music.db ./.venv/bin/alembic upgrade head
docker build -t music-platform-api:stepb .
docker run --rm -d --name stepb-api-test -p 8000:8000 \
  -v "$(pwd)/stepb_music.db:/tmp/music.db" \
  -e DATABASE_URL=sqlite:////tmp/music.db \
  music-platform-api:stepb
```

Validation:

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/
curl -I http://127.0.0.1:8000/docs
docker logs stepb-api-test
docker stop stepb-api-test
rm -f stepb_music.db
```

Checkpoint:
- Image builds.
- Container starts without crashing.
- API and docs are reachable through mapped host port.

## 🔵 Step C - Test container alone

Goal:
- Validate runtime behavior before introducing dependent services.

Recommended checks:

```bash
DATABASE_URL=sqlite:///./stepc_music.db ./.venv/bin/alembic upgrade head
docker run --rm -d --name stepc-api-test -p 8000:8000 \
  -v "$(pwd)/stepc_music.db:/tmp/music.db" \
  -e DATABASE_URL=sqlite:////tmp/music.db \
  music-platform-api:stepb
docker inspect -f '{{.State.Running}}' stepc-api-test
docker inspect -f '{{.RestartCount}}' stepc-api-test
docker logs --tail 100 stepc-api-test
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/docs
docker stop stepc-api-test
rm -f stepc_music.db
```

Checkpoint:
- Running state remains `true`.
- Restart count remains `0`.
- Logs show normal startup and no traceback.

---

Continue with [compose-guide.md](./compose-guide.md) for Step D (adding the database service with Docker Compose) and Step E (log validation).

---

## 🔗 Related documents

- [Docker Compose workflow](./compose-guide.md)
- [Kubernetes concept map](../kubernetes/k8s-concept-map.md)
- [Setup guide](../SETUP.md)
- [Architecture decisions](../ARCHITECTURE.md)
