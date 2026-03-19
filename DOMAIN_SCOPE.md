# Stage 1 - Domain Scope

## Resource: Song

A song represents one music item available in the platform.

### Proposed fields

- `id` (int, primary key)
- `title` (string, required)
- `artist` (string, required)
- `album` (string, optional)
- `duration_seconds` (int, optional)
- `release_year` (int, optional)
- `created_at` (datetime, auto-generated)

## Resource: Playlist

A playlist represents a user-curated collection of songs.

### Proposed fields

- `id` (int, primary key)
- `name` (string, required)
- `description` (string, optional)
- `is_public` (bool, default `true`)
- `created_at` (datetime, auto-generated)
- `updated_at` (datetime, auto-updated)

## Relationship: Songs <-> Playlists

- Relationship type: many-to-many
- One playlist contains many songs
- One song can be present in many playlists
- Association table: `playlist_songs`
  - `playlist_id` (FK -> playlists.id)
  - `song_id` (FK -> songs.id)
  - `added_at` (datetime, auto-generated)

This structure keeps the domain clear and extensible for upcoming CRUD stages.
