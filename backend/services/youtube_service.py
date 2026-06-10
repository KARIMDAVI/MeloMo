# youtube_service.py — Search YouTube Data API v3 for mood-appropriate music videos.
# Quota: 10,000 units/day. 1 search = 100 units. Backend cache extends this ~100x.
# videoCategoryId=10 filters to Music category — dramatically reduces non-music results.
import os
import httpx

YT_BASE = "https://www.googleapis.com/youtube/v3"


async def search_tracks(mood: str, seeds: list[str], limit: int = 20) -> list[dict]:
    """Search YouTube for music videos matching the mood seeds."""
    query = f"{' '.join(seeds[:2])} music"
    params = {
        "part": "snippet",
        "q": query,
        "type": "video",
        "videoCategoryId": "10",   # Music — without this you get cooking videos
        "maxResults": limit,
        "key": os.environ["YOUTUBE_API_KEY"],
        "relevanceLanguage": "en",
        "safeSearch": "none",
    }
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{YT_BASE}/search", params=params, timeout=8.0)
        data = r.json()

    tracks = []
    for item in data.get("items", []):
        vid = item["id"]["videoId"]
        snippet = item["snippet"]
        tracks.append({
            "id": f"youtube:{vid}",
            "title": snippet["title"],
            "artist": snippet["channelTitle"],
            "album": None,
            "duration": 0,              # Duration requires a separate videos.list call — skip for now
            "stream_url": None,         # YouTube plays via video_id in YouTubePlayerKit on iOS
            "video_id": vid,
            "artwork_url": snippet["thumbnails"]["high"]["url"],
            "source": "youtube",
            "energy": 0.7,              # YouTube moods trend higher energy by default
            "match_reason": f"Matched '{mood}' mood via YouTube Music catalog",
        })
    return tracks
