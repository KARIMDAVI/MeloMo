# models.py — Pydantic schemas for all request/response payloads.
# Keeping them here (not inline in routers) means the iOS team can read one file to understand the API contract.
from pydantic import BaseModel
from typing import Optional


class MoodGenerateRequest(BaseModel):
    input: str                              # Raw user text or mood title
    source_override: Optional[str] = None  # "jamendo" | "youtube" | "apple_music"


class TrackItem(BaseModel):
    id: str
    title: str
    artist: str
    album: Optional[str] = None
    duration: float
    stream_url: Optional[str] = None    # None for YouTube (uses video_id instead)
    video_id: Optional[str] = None      # YouTube video ID — avoids double-fetching
    artwork_url: Optional[str] = None
    source: str                         # "jamendo" | "youtube"
    energy: float
    match_reason: str


class MoodSuggestion(BaseModel):
    mood: str
    category: str
    confidence: float


class MoodGenerateResponse(BaseModel):
    mood: str
    category: str
    energy: float
    explanation: str
    source: str
    top_moods: list[MoodSuggestion]
    tracks: list[TrackItem]


class ExportRequest(BaseModel):
    tracks: list[TrackItem]
    destination: str                    # "spotify" | "youtube_music"
    auth_token: str
    playlist_name: str
    user_id: Optional[str] = None      # Required for Spotify (their API needs it)


class ExportResponse(BaseModel):
    playlist_id: str
    matched_count: int
    total_count: int
    playlist_url: Optional[str] = None
