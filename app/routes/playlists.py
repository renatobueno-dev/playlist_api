from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from app.database import get_session
from app.schemas.playlist import PlaylistCreate, PlaylistRead, PlaylistUpdate
from app.services.song_service import get_song_by_id
from app.services.playlist_service import (
    MissingSongsError,
    add_song_to_playlist,
    create_playlist,
    delete_playlist,
    get_playlist_by_id,
    list_playlists,
    remove_song_from_playlist,
    update_playlist,
)

router = APIRouter(prefix="/playlists", tags=["playlists"])
PLAYLIST_NOT_FOUND_DETAIL = "Playlist not found"
SONG_NOT_FOUND_DETAIL = "Song not found"


def format_missing_songs_detail(missing_song_ids: list[int]) -> str:
    return f"Songs not found: {missing_song_ids}"


@router.get("/", response_model=list[PlaylistRead])
def read_playlists(session: Session = Depends(get_session)) -> list[PlaylistRead]:
    return list_playlists(session)


@router.post("/", response_model=PlaylistRead, status_code=status.HTTP_201_CREATED)
def create_playlist_endpoint(
    payload: PlaylistCreate,
    session: Session = Depends(get_session),
) -> PlaylistRead:
    try:
        return create_playlist(session, payload)
    except MissingSongsError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=format_missing_songs_detail(exc.missing_song_ids),
        ) from exc


@router.get("/{playlist_id}", response_model=PlaylistRead)
def read_playlist(playlist_id: int, session: Session = Depends(get_session)) -> PlaylistRead:
    playlist = get_playlist_by_id(session, playlist_id)
    if playlist is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAYLIST_NOT_FOUND_DETAIL)
    return playlist


@router.patch("/{playlist_id}", response_model=PlaylistRead)
def update_playlist_endpoint(
    playlist_id: int,
    payload: PlaylistUpdate,
    session: Session = Depends(get_session),
) -> PlaylistRead:
    playlist = get_playlist_by_id(session, playlist_id)
    if playlist is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAYLIST_NOT_FOUND_DETAIL)
    try:
        return update_playlist(session, playlist, payload)
    except MissingSongsError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=format_missing_songs_detail(exc.missing_song_ids),
        ) from exc


@router.delete("/{playlist_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_playlist_endpoint(playlist_id: int, session: Session = Depends(get_session)) -> Response:
    playlist = get_playlist_by_id(session, playlist_id)
    if playlist is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAYLIST_NOT_FOUND_DETAIL)

    delete_playlist(session, playlist)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/{playlist_id}/songs/{song_id}",
    response_model=PlaylistRead,
    status_code=status.HTTP_201_CREATED,
)
def add_song_to_playlist_endpoint(
    playlist_id: int,
    song_id: int,
    session: Session = Depends(get_session),
) -> PlaylistRead:
    playlist = get_playlist_by_id(session, playlist_id)
    if playlist is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAYLIST_NOT_FOUND_DETAIL)

    song = get_song_by_id(session, song_id)
    if song is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=SONG_NOT_FOUND_DETAIL)

    return add_song_to_playlist(session, playlist, song)


@router.delete("/{playlist_id}/songs/{song_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_song_from_playlist_endpoint(
    playlist_id: int,
    song_id: int,
    session: Session = Depends(get_session),
) -> None:
    playlist = get_playlist_by_id(session, playlist_id)
    if playlist is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAYLIST_NOT_FOUND_DETAIL)

    song = get_song_by_id(session, song_id)
    if song is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=SONG_NOT_FOUND_DETAIL)

    remove_song_from_playlist(session, playlist, song)
    return
