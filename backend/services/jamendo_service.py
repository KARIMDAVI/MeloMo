# jamendo_service.py — Fetch CC-licensed tracks from Jamendo for a mood.
# Free tier: 50,000 API calls/month — cache aggressively to protect quota.
# groupby=artist_id prevents all 20 tracks from the same artist (real problem without it).
import os
import httpx

JAMENDO_BASE = "https://api.jamendo.com/v3.0"


async def search_tracks(mood: str, seeds: list[str], limit: int = 20) -> list[dict]:
    """Search Jamendo for mood-appropriate tracks. Returns list of track dicts."""
    query = " ".join(seeds[:3])   # Top 3 seeds keeps the query focused
    params = {
        "client_id": os.environ["JAMENDO_CLIENT_ID"],
        "format": "json",
        "limit": limit,
        "search": query,
        "audioformat": "mp32",    # 320kbps mp3 — best available free quality
        "include": "musicinfo",   # Returns BPM, tags, etc.
        "groupby": "artist_id",   # Variety over depth
    }
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{JAMENDO_BASE}/tracks/", params=params, timeout=8.0)
        data = r.json()

    tracks = []
    for t in data.get("results", []):
        tracks.append({
            "id": f"jamendo:{t['id']}",
            "title": t["name"],
            "artist": t["artist_name"],
            "album": t.get("album_name"),
            "duration": t.get("duration", 0),
            "stream_url": t.get("audio"),           # Direct .mp3 URL — plays via AVPlayer
            "artwork_url": t.get("album_image"),
            "source": "jamendo",
            "energy": 0.3,                          # Jamendo doesn't expose energy — default low for chill moods
            "match_reason": f"CC-licensed, matched '{mood}' mood",
        })
    return tracks
