# lastfm_service.py — Validate mood-to-artist matches via Last.fm crowdsourced tags.
# Not on the critical request path — used in background validation or future "why this song" enrichment.
import os
import httpx

LASTFM_BASE = "https://ws.audioscrobbler.com/2.0/"


async def get_top_artists_for_mood(mood: str, limit: int = 5) -> list[str]:
    """Get Last.fm artists most tagged with this mood keyword."""
    params = {
        "method": "tag.gettopartists",
        "tag": mood.lower(),
        "limit": limit,
        "api_key": os.environ["LASTFM_API_KEY"],
        "format": "json",
    }
    async with httpx.AsyncClient() as client:
        r = await client.get(LASTFM_BASE, params=params, timeout=5.0)
        data = r.json()
    artists = data.get("topartists", {}).get("artist", [])
    return [a["name"] for a in artists]
