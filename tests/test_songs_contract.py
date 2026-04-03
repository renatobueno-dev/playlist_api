"""Contract tests covering song CRUD behavior."""

from fastapi.testclient import TestClient


def create_song(
    client: TestClient,
    **overrides: object,
) -> dict:
    """Create one song through the API and return the response payload."""
    payload = song_expectations()
    payload.update(overrides)

    response = client.post("/songs/", json=payload)
    assert response.status_code == 201
    return response.json()


def song_expectations(**overrides: object) -> dict[str, object]:
    """Build the default expected song payload for assertions."""
    expected_payload = {
        "title": "Numb",
        "artist": "Linkin Park",
        "album": "Meteora",
        "genre": "Rock",
        "duration_seconds": 185,
        "release_year": 2003,
    }
    expected_payload.update(overrides)
    return expected_payload


def assert_song_payload(
    song: dict,
    expected: dict[str, object],
) -> None:
    """Assert that a song payload matches the expected business fields."""
    actual_payload = {field_name: song[field_name] for field_name in expected}
    assert actual_payload == expected


def assert_song_not_found(response) -> None:
    """Assert that an API response represents a missing song."""
    assert response.status_code == 404
    assert response.json() == {"detail": "Song not found"}


def test_song_create_returns_expected_payload(client: TestClient) -> None:
    """Verify creating a song returns the expected serialized payload."""
    created_song = create_song(client)

    assert_song_payload(created_song, song_expectations())


def test_song_list_includes_created_song(client: TestClient) -> None:
    """Verify the song list endpoint includes newly created songs."""
    created_song = create_song(client)

    list_response = client.get("/songs/")
    assert list_response.status_code == 200

    listed_songs = list_response.json()
    assert any(song["id"] == created_song["id"] for song in listed_songs)


def test_song_list_returns_empty_list_when_no_songs_exist(client: TestClient) -> None:
    """Verify the song list endpoint returns an empty collection initially."""
    list_response = client.get("/songs/")

    assert list_response.status_code == 200
    assert list_response.json() == []


def test_song_get_by_id_returns_created_song(client: TestClient) -> None:
    """Verify fetching by id returns the created song."""
    created_song = create_song(client)

    read_response = client.get(f"/songs/{created_song['id']}")
    assert read_response.status_code == 200

    read_song = read_response.json()
    assert read_song["id"] == created_song["id"]
    assert_song_payload(read_song, song_expectations())


def test_song_patch_updates_only_expected_fields(client: TestClient) -> None:
    """Verify patch only changes the targeted song fields."""
    created_song = create_song(client)

    update_response = client.patch(
        f"/songs/{created_song['id']}",
        json={"genre": "Alternative Rock"},
    )
    assert update_response.status_code == 200

    updated_song = update_response.json()
    assert updated_song["id"] == created_song["id"]
    assert_song_payload(updated_song, song_expectations(genre="Alternative Rock"))


def test_song_delete_removes_song(client: TestClient) -> None:
    """Verify deleting a song removes it from subsequent reads."""
    created_song = create_song(client)

    delete_response = client.delete(f"/songs/{created_song['id']}")
    assert delete_response.status_code == 204

    read_deleted_response = client.get(f"/songs/{created_song['id']}")
    assert_song_not_found(read_deleted_response)


def test_song_get_missing_id_returns_404(client: TestClient) -> None:
    """Verify reading an unknown song id returns HTTP 404."""
    response = client.get("/songs/99999")

    assert_song_not_found(response)


def test_song_patch_missing_id_returns_404(client: TestClient) -> None:
    """Verify patching an unknown song id returns HTTP 404."""
    response = client.patch("/songs/99999", json={"genre": "Any Genre"})

    assert_song_not_found(response)


def test_song_delete_missing_id_returns_404(client: TestClient) -> None:
    """Verify deleting an unknown song id returns HTTP 404."""
    response = client.delete("/songs/99999")

    assert_song_not_found(response)


def test_create_song_missing_required_field_returns_422(client: TestClient) -> None:
    """Verify missing required song fields are rejected by validation."""
    response = client.post(
        "/songs/",
        json={
            "title": "Missing Artist",
        },
    )

    assert response.status_code == 422


def test_create_song_invalid_duration_returns_422(client: TestClient) -> None:
    """Verify invalid duration values are rejected by validation."""
    response = client.post(
        "/songs/",
        json={
            "title": "Invalid Duration",
            "artist": "Unknown",
            "duration_seconds": 0,
        },
    )

    assert response.status_code == 422


def test_create_song_invalid_field_type_returns_422(client: TestClient) -> None:
    """Verify invalid field types are rejected by validation."""
    response = client.post(
        "/songs/",
        json={
            "title": {"unexpected": "object"},
            "artist": "Unknown",
            "duration_seconds": 180,
        },
    )

    assert response.status_code == 422


def test_create_song_malformed_json_returns_422(client: TestClient) -> None:
    """Verify malformed JSON bodies are rejected before route execution."""
    response = client.post(
        "/songs/",
        content='{"title":',
        headers={"content-type": "application/json"},
    )

    assert response.status_code == 422


def test_create_song_accepts_explicit_nullable_fields(client: TestClient) -> None:
    """Verify nullable song fields round-trip correctly when set to null."""
    response = client.post(
        "/songs/",
        json={
            "title": "Nullable Fields",
            "artist": "Test Artist",
            "album": None,
            "genre": None,
            "duration_seconds": None,
            "release_date": None,
            "release_year": None,
        },
    )

    assert response.status_code == 201
    song = response.json()
    assert_song_payload(
        song,
        song_expectations(
            title="Nullable Fields",
            artist="Test Artist",
            album=None,
            genre=None,
            duration_seconds=None,
            release_date=None,
            release_year=None,
        ),
    )


def test_create_song_accepts_maximum_length_fields(client: TestClient) -> None:
    """Verify documented song string limits are accepted at their boundary."""
    response = client.post(
        "/songs/",
        json={
            "title": "T" * 255,
            "artist": "A" * 255,
            "album": "B" * 255,
            "genre": "G" * 100,
            "duration_seconds": 1,
            "release_year": 2100,
        },
    )

    assert response.status_code == 201
    song = response.json()
    assert_song_payload(
        song,
        song_expectations(
            title="T" * 255,
            artist="A" * 255,
            album="B" * 255,
            genre="G" * 100,
            duration_seconds=1,
            release_year=2100,
        ),
    )
