# router.py — Decides which music source best fits a mood category.
# Lives separate from the endpoint so we can tune routing without touching API code.
# Decision: Jamendo for calm/focused (CC-licensed, no ads), YouTube for high-energy (bigger catalog).

JAMENDO_CATEGORIES = {"focused", "chill", "relaxed"}
YOUTUBE_CATEGORIES = {"energetic", "social", "magical", "emotional", "romantic", "melancholy"}


def pick_source(category: str, has_apple_music: bool = False) -> str:
    """Return the best PlaybackSource for this mood category."""
    if has_apple_music:
        return "apple_music"
    if category.lower() in JAMENDO_CATEGORIES:
        return "jamendo"
    return "youtube"  # Default to YouTube — wider catalog for unlisted moods


def mood_to_seeds(mood: str, category: str) -> list[str]:
    """Map a mood title + category to music search seed terms."""
    seed_map = {
        "focused":   ["focus instrumental", "study music", "concentration", "ambient work"],
        "calm":      ["calm music", "peaceful", "meditation", "tranquil"],
        "relaxed":   ["chill beats", "lofi", "easy listening", "downtempo"],
        "energetic": ["upbeat pop", "high energy", "dance", "workout"],
        "happy":     ["feel good", "pop uplifting", "good vibes", "summer pop"],
        "hype":      ["trap", "edm", "bass", "electro house"],
        "romantic":  ["love songs", "romantic", "intimate", "slow jams"],
        "sad":       ["emotional", "piano ballad", "sad indie", "heartbreak"],
        "social":    ["party", "dance pop", "club", "festive"],
        "magical":   ["ethereal", "cinematic", "dreamy", "ambient"],
    }
    key = mood.lower()
    return seed_map.get(key, seed_map.get(category.lower(), [mood, "music"]))
