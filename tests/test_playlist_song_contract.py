"""Contract tests for playlist-song relationship endpoints."""

from fastapi.testclient import TestClient


def create_song(client: TestClient, *, title: str) -> dict:
    """Create one song used by relationship endpoint tests."""
    response = client.post(
        "/songs/",
        json={
            "title": title,
            "artist": "Relationship Artist",
            "duration_seconds": 180,
        },
    )
    assert response.status_code == 201
    return response.json()


def create_playlist(client: TestClient, *, name: str) -> dict:
    """Create one playlist used by relationship endpoint tests."""
    response = client.post("/playlists/", json={"name": name})
    assert response.status_code == 201
    return response.json()


def test_playlist_song_link_adds_song_to_playlist(client: TestClient) -> None:
    """Verify linking a song adds it to the playlist relation."""
    song = create_song(client, title="Linked Song")
    playlist = create_playlist(client, name="Link Contract")

    add_response = client.post(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert add_response.status_code == 201

    added_song_ids = [item["id"] for item in add_response.json()["songs"]]
    assert added_song_ids == [song["id"]]


def test_playlist_song_duplicate_link_does_not_duplicate_relation(client: TestClient) -> None:
    """Verify linking the same song twice keeps a single relation."""
    song = create_song(client, title="Linked Song")
    playlist = create_playlist(client, name="Link Contract")

    first_add_response = client.post(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert first_add_response.status_code == 201

    add_again_response = client.post(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert add_again_response.status_code == 201

    second_add_song_ids = [item["id"] for item in add_again_response.json()["songs"]]
    assert second_add_song_ids.count(song["id"]) == 1


def test_playlist_song_unlink_removes_relation(client: TestClient) -> None:
    """Verify unlinking removes the related song from the playlist."""
    song = create_song(client, title="Linked Song")
    playlist = create_playlist(client, name="Link Contract")

    add_response = client.post(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert add_response.status_code == 201

    remove_response = client.delete(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert remove_response.status_code == 204

    playlist_after_remove = client.get(f"/playlists/{playlist['id']}")
    assert playlist_after_remove.status_code == 200
    assert playlist_after_remove.json()["songs"] == []


def test_playlist_song_repeated_unlink_is_idempotent(client: TestClient) -> None:
    """Verify repeated unlink calls remain successful and idempotent."""
    song = create_song(client, title="Linked Song")
    playlist = create_playlist(client, name="Link Contract")

    add_response = client.post(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert add_response.status_code == 201

    remove_response = client.delete(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert remove_response.status_code == 204

    remove_again_response = client.delete(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert remove_again_response.status_code == 204


def test_playlist_song_delete_cascades_when_song_is_removed(client: TestClient) -> None:
    """Verify deleting a song removes its playlist relation but keeps the playlist."""
    song = create_song(client, title="Cascade Song")
    playlist = create_playlist(client, name="Cascade Playlist")

    add_response = client.post(f"/playlists/{playlist['id']}/songs/{song['id']}")
    assert add_response.status_code == 201

    delete_song_response = client.delete(f"/songs/{song['id']}")
    assert delete_song_response.status_code == 204

    playlist_after_delete = client.get(f"/playlists/{playlist['id']}")
    assert playlist_after_delete.status_code == 200
    assert playlist_after_delete.json()["songs"] == []


def test_playlist_song_link_returns_404_when_playlist_missing(client: TestClient) -> None:
    """Verify linking fails when the playlist does not exist."""
    song = create_song(client, title="Existing Song")

    response = client.post(f"/playlists/99999/songs/{song['id']}")

    assert response.status_code == 404
    assert response.json() == {"detail": "Playlist not found"}


def test_playlist_song_link_returns_404_when_song_missing(client: TestClient) -> None:
    """Verify linking fails when the song does not exist."""
    playlist = create_playlist(client, name="Existing Playlist")

    response = client.post(f"/playlists/{playlist['id']}/songs/99999")

    assert response.status_code == 404
    assert response.json() == {"detail": "Song not found"}


def test_playlist_song_unlink_returns_404_when_playlist_missing(client: TestClient) -> None:
    """Verify unlinking fails when the playlist does not exist."""
    song = create_song(client, title="Existing Song")

    response = client.delete(f"/playlists/99999/songs/{song['id']}")

    assert response.status_code == 404
    assert response.json() == {"detail": "Playlist not found"}


def test_playlist_song_unlink_returns_404_when_song_missing(client: TestClient) -> None:
    """Verify unlinking fails when the song does not exist."""
    playlist = create_playlist(client, name="Existing Playlist")

    response = client.delete(f"/playlists/{playlist['id']}/songs/99999")

    assert response.status_code == 404
    assert response.json() == {"detail": "Song not found"}


def test_playlist_song_ids_patch_replaces_and_deduplicates_links(client: TestClient) -> None:
    """Verify patch can replace playlist links while deduplicating ids."""
    first_song = create_song(client, title="First")
    second_song = create_song(client, title="Second")

    playlist_response = client.post(
        "/playlists/",
        json={
            "name": "Replace Links",
            "song_ids": [first_song["id"]],
        },
    )
    assert playlist_response.status_code == 201
    playlist_id = playlist_response.json()["id"]

    replace_response = client.patch(
        f"/playlists/{playlist_id}",
        json={"song_ids": [second_song["id"], second_song["id"]]},
    )
    assert replace_response.status_code == 200
    song_ids = [song["id"] for song in replace_response.json()["songs"]]
    assert song_ids == [second_song["id"]]


def test_playlist_song_relation_rejects_invalid_identifier_types(client: TestClient) -> None:
    """Verify relationship endpoints reject invalid path parameter types."""
    invalid_playlist_id_response = client.post("/playlists/invalid/songs/1")
    assert invalid_playlist_id_response.status_code == 422

    invalid_song_id_response = client.post("/playlists/1/songs/invalid")
    assert invalid_song_id_response.status_code == 422
