from fastapi.testclient import TestClient


def create_song(
    client: TestClient,
    **overrides: object,
) -> dict:
    payload = {
        "title": "Numb",
        "artist": "Linkin Park",
        "album": "Meteora",
        "genre": "Rock",
        "duration_seconds": 185,
        "release_year": 2003,
    }
    payload.update(overrides)

    response = client.post("/songs/", json=payload)
    assert response.status_code == 201
    return response.json()


def assert_song_payload(
    song: dict,
    *,
    song_id: int | None = None,
    expected: dict[str, object] | None = None,
) -> None:
    expected_payload = {
        "title": "Numb",
        "artist": "Linkin Park",
        "album": "Meteora",
        "genre": "Rock",
        "duration_seconds": 185,
        "release_year": 2003,
    }
    if expected is not None:
        expected_payload.update(expected)

    if song_id is not None:
        assert song["id"] == song_id
    actual_payload = {field_name: song[field_name] for field_name in expected_payload}
    assert actual_payload == expected_payload


def assert_song_not_found(response) -> None:
    assert response.status_code == 404
    assert response.json() == {"detail": "Song not found"}


def test_song_create_returns_expected_payload(client: TestClient) -> None:
    created_song = create_song(client)

    assert_song_payload(created_song)


def test_song_list_includes_created_song(client: TestClient) -> None:
    created_song = create_song(client)

    list_response = client.get("/songs/")
    assert list_response.status_code == 200

    listed_songs = list_response.json()
    assert any(song["id"] == created_song["id"] for song in listed_songs)


def test_song_get_by_id_returns_created_song(client: TestClient) -> None:
    created_song = create_song(client)

    read_response = client.get(f"/songs/{created_song['id']}")
    assert read_response.status_code == 200

    assert_song_payload(read_response.json(), song_id=created_song["id"])


def test_song_patch_updates_only_expected_fields(client: TestClient) -> None:
    created_song = create_song(client)

    update_response = client.patch(
        f"/songs/{created_song['id']}",
        json={"genre": "Alternative Rock"},
    )
    assert update_response.status_code == 200

    assert_song_payload(
        update_response.json(),
        song_id=created_song["id"],
        expected={"genre": "Alternative Rock"},
    )


def test_song_delete_removes_song(client: TestClient) -> None:
    created_song = create_song(client)

    delete_response = client.delete(f"/songs/{created_song['id']}")
    assert delete_response.status_code == 204

    read_deleted_response = client.get(f"/songs/{created_song['id']}")
    assert_song_not_found(read_deleted_response)


def test_song_get_missing_id_returns_404(client: TestClient) -> None:
    response = client.get("/songs/99999")

    assert_song_not_found(response)


def test_song_patch_missing_id_returns_404(client: TestClient) -> None:
    response = client.patch("/songs/99999", json={"genre": "Any Genre"})

    assert_song_not_found(response)


def test_song_delete_missing_id_returns_404(client: TestClient) -> None:
    response = client.delete("/songs/99999")

    assert_song_not_found(response)


def test_create_song_missing_required_field_returns_422(client: TestClient) -> None:
    response = client.post(
        "/songs/",
        json={
            "title": "Missing Artist",
        },
    )

    assert response.status_code == 422


def test_create_song_invalid_duration_returns_422(client: TestClient) -> None:
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
    response = client.post(
        "/songs/",
        json={
            "title": {"unexpected": "object"},
            "artist": "Unknown",
            "duration_seconds": 180,
        },
    )

    assert response.status_code == 422
