# Checkpoint Level 3 - Stage 1

Minimal FastAPI + SQLAlchemy structure for a music platform domain.

## Scope defined

- `Song` resource
- `Playlist` resource
- Many-to-many relationship through `playlist_songs`

See [DOMAIN_SCOPE.md](./DOMAIN_SCOPE.md) for detailed fields and relationship decisions.

## Project structure

```text
app/
  main.py
  database.py
  models/
  schemas/
  routes/
  services/
```

## Run locally

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Start the API:

```bash
uvicorn app.main:app --reload
```

4. Open docs:

- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

## Initial endpoints

- `GET /`
- `GET /health`
- `GET /songs/`
- `POST /songs/`
- `GET /playlists/`
- `POST /playlists/`
