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

> `DATABASE_URL` is always required — the app raises `RuntimeError` at startup if it is missing. For standalone container runs, use a writable path such as `/tmp/music.db` (`sqlite:////tmp/music.db`).

```bash
docker build -t music-platform-api:stepb .
docker run --rm -d --name stepb-api-test -p 8000:8000 -e DATABASE_URL=sqlite:////tmp/music.db music-platform-api:stepb
```

Validation:

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/
curl -I http://127.0.0.1:8000/docs
docker logs stepb-api-test
docker stop stepb-api-test
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
docker run --rm -d --name stepc-api-test -p 8000:8000 -e DATABASE_URL=sqlite:////tmp/music.db music-platform-api:stepb
docker inspect -f '{{.State.Running}}' stepc-api-test
docker inspect -f '{{.RestartCount}}' stepc-api-test
docker logs --tail 100 stepc-api-test
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/docs
docker stop stepc-api-test
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
