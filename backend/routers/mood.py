# mood.py — Single endpoint: classify mood + fetch playlist in one round trip.
# Combining classification + playlist generation saves one network request (important on cold starts).
# Jamendo → YouTube fallback ensures users never get an empty playlist.
from fastapi import APIRouter, HTTPException
from models import MoodGenerateRequest, MoodGenerateResponse, TrackItem, MoodSuggestion
from services.groq_service import classify_mood
from services.jamendo_service import search_tracks as jamendo_search
from services.youtube_service import search_tracks as youtube_search
from router import pick_source, mood_to_seeds
from cache import playlist_cache

router = APIRouter()


@router.post("/generate", response_model=MoodGenerateResponse)
async def generate(req: MoodGenerateRequest):
    # Cache check — avoids Groq + music API calls for repeated mood inputs within 1 hour
    cache_key = f"{req.input.lower().strip()}:{req.source_override or ''}"
    if cached := playlist_cache.get(cache_key):
        return cached

    # Classify mood via Groq LLM
    try:
        classification = await classify_mood(req.input)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Mood classification failed: {e}")

    mood = classification.get("mood", req.input.title())
    category = classification.get("category", "general")
    energy = classification.get("energy", 0.5)
    explanation = classification.get("explanation", "Music matched to your mood")
    top_moods = [MoodSuggestion(**m) for m in classification.get("top_moods", [])]

    source = req.source_override or pick_source(category)
    seeds = mood_to_seeds(mood, category)

    # Fetch tracks — Jamendo fallback to YouTube if results are sparse
    raw_tracks = []
    if source == "jamendo":
        raw_tracks = await jamendo_search(mood, seeds)
        if len(raw_tracks) < 5:     # Jamendo returned too few — YouTube has bigger catalog
            source = "youtube"
            raw_tracks = await youtube_search(mood, seeds)
    elif source == "youtube":
        raw_tracks = await youtube_search(mood, seeds)

    if not raw_tracks:
        raise HTTPException(status_code=404, detail="No tracks found for this mood")

    tracks = [TrackItem(**t) for t in raw_tracks]
    result = MoodGenerateResponse(
        mood=mood, category=category, energy=energy,
        explanation=explanation, source=source,
        top_moods=top_moods, tracks=tracks,
    )

    playlist_cache.set(cache_key, result)
    return result
