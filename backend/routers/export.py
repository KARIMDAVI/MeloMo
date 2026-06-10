# export.py — Create playlists in Spotify or YouTube Music.
# Apple Music export is iOS-only (MusicKit on-device) — intentionally not handled here.
# Both providers follow the same pattern: create playlist → search/match tracks → add.
import httpx
from fastapi import APIRouter, HTTPException
from models import ExportRequest, ExportResponse

router = APIRouter()


@router.post("/export", response_model=ExportResponse)
async def export_playlist(req: ExportRequest):
    if req.destination == "spotify":
        return await _export_to_spotify(req)
    elif req.destination == "youtube_music":
        return await _export_to_youtube_music(req)
    else:
        raise HTTPException(status_code=400, detail=f"Unknown destination: {req.destination}")


async def _export_to_spotify(req: ExportRequest) -> ExportResponse:
    headers = {"Authorization": f"Bearer {req.auth_token}", "Content-Type": "application/json"}
    async with httpx.AsyncClient() as client:
        # Create the playlist shell
        pl = await client.post(
            f"https://api.spotify.com/v1/users/{req.user_id}/playlists",
            headers=headers,
            json={"name": req.playlist_name, "public": False, "description": "Created by MeloMo"},
        )
        pl.raise_for_status()
        playlist_id = pl.json()["id"]

        # Search Spotify for each track and collect URIs
        uris, matched = [], 0
        for track in req.tracks:
            r = await client.get(
                "https://api.spotify.com/v1/search",
                headers=headers,
                params={"q": f"{track.title} {track.artist}", "type": "track", "limit": 1},
            )
            items = r.json().get("tracks", {}).get("items", [])
            if items:
                uris.append(items[0]["uri"])
                matched += 1

        if uris:
            await client.post(
                f"https://api.spotify.com/v1/playlists/{playlist_id}/tracks",
                headers=headers,
                json={"uris": uris},
            )

    return ExportResponse(
        playlist_id=playlist_id,
        matched_count=matched,
        total_count=len(req.tracks),
        playlist_url=f"https://open.spotify.com/playlist/{playlist_id}",
    )


async def _export_to_youtube_music(req: ExportRequest) -> ExportResponse:
    headers = {"Authorization": f"Bearer {req.auth_token}", "Content-Type": "application/json"}
    async with httpx.AsyncClient() as client:
        pl = await client.post(
            "https://www.googleapis.com/youtube/v3/playlists",
            headers=headers,
            params={"part": "snippet,status"},
            json={"snippet": {"title": req.playlist_name}, "status": {"privacyStatus": "private"}},
        )
        pl.raise_for_status()
        playlist_id = pl.json()["id"]

        # Only add tracks that already came from YouTube (they have a video_id ready to use)
        matched = 0
        for track in req.tracks:
            if track.video_id:
                await client.post(
                    "https://www.googleapis.com/youtube/v3/playlistItems",
                    headers=headers,
                    params={"part": "snippet"},
                    json={"snippet": {
                        "playlistId": playlist_id,
                        "resourceId": {"kind": "youtube#video", "videoId": track.video_id},
                    }},
                )
                matched += 1

    return ExportResponse(
        playlist_id=playlist_id,
        matched_count=matched,
        total_count=len(req.tracks),
        playlist_url=f"https://music.youtube.com/playlist?list={playlist_id}",
    )
