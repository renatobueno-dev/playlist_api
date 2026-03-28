import logging
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy.exc import OperationalError

from app.database import engine
from app.models import Base
from app.routes.health import router as health_router
from app.routes.playlists import router as playlists_router
from app.routes.songs import router as songs_router

logger = logging.getLogger(__name__)
STARTUP_DB_MAX_RETRIES = int(os.getenv("STARTUP_DB_MAX_RETRIES", "20"))
STARTUP_DB_RETRY_SECONDS = float(os.getenv("STARTUP_DB_RETRY_SECONDS", "2"))


def initialize_database() -> None:
    for attempt in range(1, STARTUP_DB_MAX_RETRIES + 1):
        try:
            Base.metadata.create_all(bind=engine)
            if attempt > 1:
                logger.info("Database became reachable on startup attempt %s.", attempt)
            return
        except OperationalError as exc:
            if attempt == STARTUP_DB_MAX_RETRIES:
                logger.exception(
                    "Database startup failed after %s attempts.",
                    STARTUP_DB_MAX_RETRIES,
                )
                raise
            logger.warning(
                "Database not ready on startup attempt %s/%s: %s. Retrying in %.1f seconds.",
                attempt,
                STARTUP_DB_MAX_RETRIES,
                exc,
                STARTUP_DB_RETRY_SECONDS,
            )
            time.sleep(STARTUP_DB_RETRY_SECONDS)


@asynccontextmanager
async def lifespan(_: FastAPI):
    initialize_database()
    yield


app = FastAPI(
    title="Music Platform API",
    version="1.6.0",
    lifespan=lifespan,
)


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Music Platform API is running"}


app.include_router(health_router)
app.include_router(songs_router)
app.include_router(playlists_router)
