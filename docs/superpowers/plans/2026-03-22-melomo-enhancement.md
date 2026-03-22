# MeloMo Enhancement Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform MeloMo into a free, AI-powered mood music app with in-app playback (Jamendo + YouTube), natural language mood input, and one-tap playlist export to Spotify / Apple Music / YouTube Music.

**Architecture:** iOS SwiftUI app backed by a lightweight FastAPI Python service (Render free tier). The backend handles NL mood classification (Groq LLM), smart source routing, and playlist curation from Jamendo + YouTube Data API. The iOS app plays tracks via AVPlayer (Jamendo) or YouTubePlayerKit (YouTube) and exports playlists via Spotify Web API, YouTube Data API, or on-device MusicKit.

**Tech Stack:** SwiftUI, MusicKit, AVFoundation, YouTubePlayerKit, Speech framework, SwiftData, FontAwesome.swift | Python 3.11, FastAPI, Groq SDK, httpx, Uvicorn | Jamendo API, YouTube Data v3, Last.fm API, Spotify Web API

**Spec:** `docs/superpowers/specs/2026-03-22-melomo-enhancement-design.md`

---

## File Map

### New iOS Files
| File | Responsibility |
|------|---------------|
| `MeloMo/Utilities/Icons.swift` | All FA icon constants — single source of truth |
| `MeloMo/Models/PlaybackSource.swift` | `PlaybackSource` enum (jamendo / youtube / appleMusic) |
| `MeloMo/Models/SavedPlaylist.swift` | SwiftData `@Model` for persisted playlists |
| `MeloMo/Managers/BackendClient.swift` | URLSession wrapper for Python backend API |
| `MeloMo/Managers/JamendoPlayer.swift` | AVPlayer wrapper for Jamendo stream URLs |
| `MeloMo/Managers/YouTubePlaybackManager.swift` | YouTubePlayerKit coordinator |
| `MeloMo/Managers/ExportManager.swift` | Spotify + YouTube Music playlist export |
| `MeloMo/Managers/SpeechManager.swift` | Speech recognition → text |
| `MeloMo/Views/NowPlayingView.swift` | Full-screen now playing screen |
| `MeloMo/Views/LibraryView.swift` | Saved + exported playlists tab |
| `MeloMo/Views/SubViews/NLMoodInputView.swift` | Natural language + voice input bar |
| `MeloMo/Views/SubViews/MoodSuggestionRow.swift` | Mood suggestion after NL classification |
| `MeloMo/Views/SubViews/ExportSheetView.swift` | Clone-to-app destination picker |
| `MeloMo/Views/SubViews/WhyThisSongView.swift` | Match explanation expandable view |
| `MeloMo/Views/SubViews/StreakBannerView.swift` | Streak counter for Stats tab |

### Modified iOS Files
| File | Changes |
|------|---------|
| `MeloMo/Models/Models.swift` | Add `streamURL`, `matchReason` to `MusicTrack`; keep `Provider` enum for export |
| `MeloMo/Models/EnhancedMoods.swift` | Fix duplicate emojis (⚡ ×2, 🎭 ×2) |
| `MeloMo/Managers/MusicController.swift` | Fix `allMoods` → `enhancedMoods`, fix dead `do/catch`, add `PlaybackSource` routing |
| `MeloMo/Views/ContentView.swift` | Update tab bar to 4 redesigned tabs with FA icons |
| `MeloMo/Views/EnhancedVibesView.swift` | Add NL input bar, category pills (8 categories), FA icons |
| `MeloMo/Views/SubViews/StatsView.swift` | Add streak counter, mood frequency, listening time |
| `MeloMo/Views/SubViews/ChallengesView.swift` | Replace stubs with real badge/challenge data |
| `MeloMo/Core/MeloMoApp.swift` | Add SwiftData `modelContainer` |

### New Backend Files
| File | Responsibility |
|------|---------------|
| `backend/main.py` | FastAPI app, CORS, router registration |
| `backend/models.py` | Pydantic request/response models |
| `backend/router.py` | Source routing logic (mood → PlaybackSource) |
| `backend/cache.py` | In-memory TTL cache (dict + timestamps) |
| `backend/services/groq_service.py` | Groq LLM mood classification |
| `backend/services/jamendo_service.py` | Jamendo REST API track search |
| `backend/services/youtube_service.py` | YouTube Data v3 search |
| `backend/services/lastfm_service.py` | Last.fm mood tag validation |
| `backend/requirements.txt` | Python dependencies |
| `backend/render.yaml` | Render deployment config |

---

## Chunk 1: iOS Foundation

*Establishes the base layer all other chunks build on. No UI changes. All testable via unit tests or Xcode previews.*

---

### Task 1: Add FontAwesome.swift Package

**Files:**
- Modify: `MeloMo.xcodeproj` (Swift Package dependency)
- Create: `MeloMo/Utilities/Icons.swift`

- [ ] **Step 1: Add Swift Package in Xcode**

  In Xcode: File → Add Package Dependencies
  URL: `https://github.com/thii/FontAwesome.swift`
  Version: Up to Next Major from `5.15.0`
  Target: MeloMo

- [ ] **Step 2: Create `Icons.swift`**

```swift
// Icons.swift
// Single source of truth for all FontAwesome icons.
// Why: Prevents magic strings scattered through views — one rename fixes everything.
import FontAwesome

enum Icons {
    // Tabs
    static let vibes     = String.fontAwesomeIcon(name: .music)
    static let library   = String.fontAwesomeIcon(name: .layerGroup)
    static let stats     = String.fontAwesomeIcon(name: .chartBar)
    static let profile   = String.fontAwesomeIcon(name: .circleUser)

    // Playback
    static let play      = String.fontAwesomeIcon(name: .circlePlay)
    static let pause     = String.fontAwesomeIcon(name: .circlePause)
    static let skipNext  = String.fontAwesomeIcon(name: .forwardStep)
    static let skipPrev  = String.fontAwesomeIcon(name: .backwardStep)

    // Actions
    static let mic       = String.fontAwesomeIcon(name: .microphone)
    static let heart     = String.fontAwesomeIcon(name: .heart)
    static let export    = String.fontAwesomeIcon(name: .fileExport)
    static let search    = String.fontAwesomeIcon(name: .magnifyingGlass)
    static let info      = String.fontAwesomeIcon(name: .circleInfo)
    static let close     = String.fontAwesomeIcon(name: .xmark)
    static let fire      = String.fontAwesomeIcon(name: .fire)
    static let trophy    = String.fontAwesomeIcon(name: .trophy)
    static let gear      = String.fontAwesomeIcon(name: .gear)

    // Brands
    static let spotify   = String.fontAwesomeIcon(name: .spotify)
    static let youtube   = String.fontAwesomeIcon(name: .youtube)
    static let apple     = String.fontAwesomeIcon(name: .apple)

    // Helper: returns a SwiftUI Text view with the icon at given size
    static func icon(_ name: FontAwesome, size: CGFloat = 20, style: FontAwesomeStyle = .solid) -> Text {
        Text(String.fontAwesomeIcon(name: name))
            .font(Font.fontAwesome(ofSize: size, style: style))
    }
}
```

- [ ] **Step 3: Verify build compiles with no errors**

  Cmd+B in Xcode. Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add MeloMo/Utilities/Icons.swift
git commit -m "feat: add FontAwesome.swift package and Icons constants"
```

---

### Task 2: Add `PlaybackSource` Enum

**Files:**
- Create: `MeloMo/Models/PlaybackSource.swift`

- [ ] **Step 1: Create the file**

```swift
// PlaybackSource.swift
// Separates "where music plays in-app" from Provider (which is "where to export").
// Decision: Jamendo and YouTube are playback-only sources — not export destinations.
import Foundation

enum PlaybackSource: String, CaseIterable, Codable, Identifiable {
    case appleMusic = "Apple Music"   // MusicKit — requires subscription
    case youtube    = "YouTube"       // YouTubePlayerKit — free, mainstream
    case jamendo    = "Jamendo"       // AVPlayer — free, CC, no ads

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appleMusic: return Icons.apple
        case .youtube:    return Icons.youtube
        case .jamendo:    return "🍃" // Jamendo has no FA brand icon — leaf fits
        }
    }

    var isFree: Bool { self != .appleMusic }
    var requiresSubscription: Bool { self == .appleMusic }
}
```

- [ ] **Step 2: Commit**

```bash
git add MeloMo/Models/PlaybackSource.swift
git commit -m "feat: add PlaybackSource enum (jamendo/youtube/appleMusic)"
```

---

### Task 3: Extend `MusicTrack` + Fix `MusicController` Bugs

**Files:**
- Modify: `MeloMo/Models/Models.swift` (lines 176–203)
- Modify: `MeloMo/Managers/MusicController.swift`

- [ ] **Step 1: Add `streamURL` and `matchReason` to `MusicTrack`**

  In `Models.swift`, add two optional fields to `MusicTrack`:

```swift
struct MusicTrack: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let artworkURL: URL?
    let duration: TimeInterval
    let energy: Double
    let genre: String?
    let mood: String?
    // NEW: Jamendo / backend-provided stream URL
    let streamURL: URL?
    // NEW: Why this song matches the mood (from backend)
    let matchReason: String?

    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, artworkURL, duration, energy, genre, mood
        case streamURL = "stream_url"
        case matchReason = "match_reason"
    }

    init(id: String, title: String, artist: String, album: String? = nil,
         artworkURL: URL? = nil, duration: TimeInterval, energy: Double,
         genre: String? = nil, mood: String? = nil,
         streamURL: URL? = nil, matchReason: String? = nil) {
        self.id = id; self.title = title; self.artist = artist
        self.album = album; self.artworkURL = artworkURL
        self.duration = duration; self.energy = energy
        self.genre = genre; self.mood = mood
        self.streamURL = streamURL; self.matchReason = matchReason
    }
}
```

- [ ] **Step 2: Change `recentMoods` and `favoriteMoods` from `[Mood]` to `[EnhancedMood]`**

  In `MusicController.swift`, find the `@Published` property declarations and update their types:

```swift
// Before:
@Published var recentMoods: [Mood] = []
@Published var favoriteMoods: [Mood] = []

// After:
@Published var recentMoods: [EnhancedMood] = []
@Published var favoriteMoods: [EnhancedMood] = []
```

  Also update `addToRecentMoods` and any sort/filter helpers to use `EnhancedMood` instead of `Mood`.

- [ ] **Step 3: Fix `allMoods` → `enhancedMoods` in `MusicController.swift`**

  Find all references to `allMoods` in `MusicController.swift` (lines 233, 237, 243, 244) and replace with `enhancedMoods`. Also update the return types from `[Mood]` to `[EnhancedMood]`:

```swift
// Before (broken — allMoods doesn't exist):
func getMoodsByCategory(_ category: MoodCategory) -> [Mood] {
    return allMoods.filter { $0.category == category }
}

// After (correct):
func getMoodsByCategory(_ category: MoodCategory) -> [EnhancedMood] {
    return enhancedMoods.filter { $0.category == category }
}

func getPopularMoods() -> [EnhancedMood] {
    return enhancedMoods.filter { $0.popularity >= 4 }
}

func getRandomMood() -> EnhancedMood? {
    let available = enhancedMoods.filter { mood in
        !recentMoods.contains { $0.title == mood.title }
    }
    return available.randomElement() ?? enhancedMoods.randomElement()
}
```

- [ ] **Step 4: Fix the dead `do/catch` in `refreshAuthorizationStatus`**

  `MusicAuthorization.request()` is not throwing. Remove the outer `do/catch`:

```swift
func refreshAuthorizationStatus() async {
    switch MusicAuthorization.currentStatus {
    case .authorized:
        isAuthorizedForAppleMusic = true
        Haptics.successPattern()
    case .notDetermined:
        let status = await MusicAuthorization.request()
        isAuthorizedForAppleMusic = (status == .authorized)
        isAuthorizedForAppleMusic ? Haptics.successPattern() : Haptics.error()
    default:
        isAuthorizedForAppleMusic = false
        Haptics.error()
    }
}
```

- [ ] **Step 5: Build and verify no errors**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 6: Commit**

```bash
git add MeloMo/Models/Models.swift MeloMo/Managers/MusicController.swift
git commit -m "fix: extend MusicTrack, migrate recentMoods to [EnhancedMood], fix allMoods and dead do/catch"
```

---

### Task 4: Fix Duplicate Emojis in `EnhancedMoods.swift`

**Files:**
- Modify: `MeloMo/Models/EnhancedMoods.swift`

- [ ] **Step 1: Find and fix duplicates**

  Currently: `⚡` is used for both "Excited" and "Electric". `🎭` is used for both "Melancholy" and "Dramatic".

  Change:
  - "Electric" → `🌩️` (thunderstorm — distinct from bolt)
  - "Dramatic" → `🎪` (tent — theatrical, distinct from masks)

```swift
// In enhancedMoods array — find "Electric" mood:
EnhancedMood(
    emoji: "🌩️",   // was ⚡ — now unique
    imageName: "Hype",
    title: "Electric",
    ...
)

// Find "Dramatic" mood:
EnhancedMood(
    emoji: "🎪",   // was 🎭 — now unique
    imageName: "Magical",
    title: "Dramatic",
    ...
)
```

- [ ] **Step 2: Commit**

```bash
git add MeloMo/Models/EnhancedMoods.swift
git commit -m "fix: resolve duplicate emojis in EnhancedMoods (Electric, Dramatic)"
```

---

### Task 5: Add SwiftData Persistence Model

**Files:**
- Create: `MeloMo/Models/SavedPlaylist.swift`
- Modify: `MeloMo/Core/MeloMoApp.swift`

- [ ] **Step 1: Create `SavedPlaylist.swift`**

```swift
// SavedPlaylist.swift
// SwiftData model for persisting generated playlists.
// Why SwiftData over UserDefaults: track arrays are too large + structured for UserDefaults.
// SwiftData gives us iCloud sync for free in a future update.
import SwiftData
import Foundation

@Model
class SavedPlaylist {
    var id: UUID
    var name: String
    var moodTitle: String
    var moodEmoji: String
    var explanation: String
    var trackData: Data        // JSONEncoded [MusicTrack] — SwiftData can't store custom Codable arrays directly
    var source: String         // PlaybackSource.rawValue
    var createdAt: Date
    var exportedTo: [String]   // ["spotify", "apple_music", "youtube_music"]

    init(name: String, moodTitle: String, moodEmoji: String,
         explanation: String, tracks: [MusicTrack],
         source: PlaybackSource) {
        self.id = UUID()
        self.name = name
        self.moodTitle = moodTitle
        self.moodEmoji = moodEmoji
        self.explanation = explanation
        self.trackData = (try? JSONEncoder().encode(tracks)) ?? Data()
        self.source = source.rawValue
        self.createdAt = Date()
        self.exportedTo = []
    }

    var tracks: [MusicTrack] {
        (try? JSONDecoder().decode([MusicTrack].self, from: trackData)) ?? []
    }
}
```

- [ ] **Step 2: Register SwiftData container in `MeloMoApp.swift`**

```swift
// MeloMoApp.swift — add modelContainer modifier
@main
struct MeloMoApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(authManager)
        }
        .modelContainer(for: SavedPlaylist.self)  // Add this line
    }
}
```

- [ ] **Step 3: Build and verify**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add MeloMo/Models/SavedPlaylist.swift MeloMo/Core/MeloMoApp.swift
git commit -m "feat: add SwiftData SavedPlaylist model and register modelContainer"
```

---

## Chunk 2: Python Backend

*Self-contained FastAPI service. Can be developed and tested independently of the iOS app.*

---

### Task 6: Backend Project Setup

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/render.yaml`
- Create: `backend/main.py`
- Create: `backend/models.py`

- [ ] **Step 1: Create `backend/requirements.txt`**

```
fastapi==0.115.0
uvicorn[standard]==0.30.0
groq==0.9.0
httpx==0.27.0
pydantic==2.7.0
python-dotenv==1.0.0
```

- [ ] **Step 2: Create `backend/render.yaml`**

```yaml
services:
  - type: web
    name: melomo-backend
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: GROQ_API_KEY
        sync: false
      - key: LASTFM_API_KEY
        sync: false
      - key: JAMENDO_CLIENT_ID
        sync: false
      - key: YOUTUBE_API_KEY
        sync: false
      - key: SPOTIFY_CLIENT_ID
        sync: false
      - key: SPOTIFY_CLIENT_SECRET
        sync: false
```

- [ ] **Step 3: Create `backend/models.py`**

```python
# models.py — Pydantic schemas for all request/response payloads.
from pydantic import BaseModel
from typing import Optional

class MoodGenerateRequest(BaseModel):
    input: str                        # Raw user text or mood title
    source_override: Optional[str] = None  # "jamendo" | "youtube" | "apple_music"

class TrackItem(BaseModel):
    id: str
    title: str
    artist: str
    album: Optional[str] = None
    duration: float
    stream_url: Optional[str] = None  # None for YouTube (uses video_id)
    video_id: Optional[str] = None    # YouTube video ID
    artwork_url: Optional[str] = None
    source: str                       # "jamendo" | "youtube"
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
    destination: str                  # "spotify" | "youtube_music"
    auth_token: str
    playlist_name: str
    user_id: Optional[str] = None     # Required for Spotify

class ExportResponse(BaseModel):
    playlist_id: str
    matched_count: int
    total_count: int
    playlist_url: Optional[str] = None
```

- [ ] **Step 4: Create `backend/main.py`**

```python
# main.py — FastAPI entry point.
# Routers are registered in Task 9 after their modules exist.
# Starting without them lets us verify the scaffold in isolation first.
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="MeloMo Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Tighten to app bundle ID in production
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok"}
```

- [ ] **Step 5: Install deps and verify server starts**

```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
# Expected: Uvicorn running on http://127.0.0.1:8000
curl http://127.0.0.1:8000/health
# Expected: {"status":"ok"}
```

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat: backend project scaffold (FastAPI + Pydantic models + Render config)"
```

---

### Task 7: Cache + Source Router

**Files:**
- Create: `backend/cache.py`
- Create: `backend/router.py`

- [ ] **Step 1: Create `backend/cache.py`**

```python
# cache.py — Simple in-memory TTL cache. No Redis needed at this scale.
# Resets on cold start — that's fine. Same mood hit twice in 1 hour returns same playlist.
import time

class TTLCache:
    def __init__(self, ttl_seconds: int = 3600):
        self._store: dict = {}
        self._ttl = ttl_seconds

    def get(self, key: str):
        entry = self._store.get(key)
        if entry and time.time() - entry["ts"] < self._ttl:
            return entry["value"]
        return None

    def set(self, key: str, value):
        self._store[key] = {"value": value, "ts": time.time()}

    def clear(self):
        self._store.clear()

# Singleton — shared across all requests in one process
playlist_cache = TTLCache(ttl_seconds=3600)
```

- [ ] **Step 2: Create `backend/router.py`**

```python
# router.py — Decides which music source best fits a mood.
# This logic lives here, not in the endpoint, so it's easy to adjust without touching API code.

JAMENDO_CATEGORIES = {"focused", "chill", "relaxed"}
YOUTUBE_CATEGORIES = {"energetic", "social", "magical", "emotional", "romantic", "melancholy"}

def pick_source(category: str, has_apple_music: bool = False) -> str:
    """Return the best PlaybackSource for this mood category."""
    if has_apple_music:
        return "apple_music"
    if category.lower() in JAMENDO_CATEGORIES:
        return "jamendo"
    return "youtube"

def mood_to_seeds(mood: str, category: str) -> list[str]:
    """Map a mood title + category to search seed terms."""
    seed_map = {
        "focused":      ["focus instrumental", "study music", "concentration", "ambient work"],
        "calm":         ["calm music", "peaceful", "meditation", "tranquil"],
        "relaxed":      ["chill beats", "lofi", "easy listening", "downtempo"],
        "energetic":    ["upbeat pop", "high energy", "dance", "workout"],
        "happy":        ["feel good", "pop uplifting", "good vibes", "summer pop"],
        "hype":         ["trap", "edm", "bass", "electro house"],
        "romantic":     ["love songs", "romantic", "intimate", "slow jams"],
        "sad":          ["emotional", "piano ballad", "sad indie", "heartbreak"],
        "social":       ["party", "dance pop", "club", "festive"],
        "magical":      ["ethereal", "cinematic", "dreamy", "ambient"],
    }
    key = mood.lower()
    return seed_map.get(key, seed_map.get(category.lower(), [mood, "music"]))
```

- [ ] **Step 3: Test router logic**

```bash
cd backend
python -c "
from router import pick_source, mood_to_seeds
assert pick_source('focused') == 'jamendo'
assert pick_source('energetic') == 'youtube'
assert pick_source('focused', has_apple_music=True) == 'apple_music'
assert 'focus instrumental' in mood_to_seeds('focused', 'focused')
print('Router tests passed')
"
```

Expected: `Router tests passed`

- [ ] **Step 4: Commit**

```bash
git add backend/cache.py backend/router.py
git commit -m "feat: backend cache (TTL dict) and mood source router"
```

---

### Task 8: Groq + Last.fm Services

**Files:**
- Create: `backend/services/groq_service.py`
- Create: `backend/services/lastfm_service.py`
- Create: `backend/.env.example`

- [ ] **Step 1: Create `backend/.env.example`**

```
GROQ_API_KEY=your_groq_key_here
LASTFM_API_KEY=your_lastfm_key_here
JAMENDO_CLIENT_ID=your_jamendo_client_id_here
YOUTUBE_API_KEY=your_youtube_key_here
SPOTIFY_CLIENT_ID=your_spotify_client_id_here
SPOTIFY_CLIENT_SECRET=your_spotify_secret_here
```

  Copy to `.env` and fill in keys. Add `.env` to `.gitignore`.

- [ ] **Step 2: Create `backend/services/groq_service.py`**

```python
# groq_service.py — Classify free-text mood input into a structured mood.
# Groq's free tier: 30 req/min, Llama 3 70B. Fast enough for real-time use.
# AsyncGroq is required — sync Groq.chat.completions.create() blocks the event loop.
import os
from groq import AsyncGroq
import json

client = AsyncGroq(api_key=os.environ["GROQ_API_KEY"])

SYSTEM_PROMPT = """You are a mood classifier for a music app. Given user input, return JSON with:
- mood: the closest mood name (e.g. "Focused", "Happy", "Calm", "Energetic", "Sad", "Romantic")
- category: one of [energetic, chill, focused, emotional, romantic, social, magical, melancholy]
- energy: float 0.0-1.0 (0=very calm, 1=maximum energy)
- explanation: one sentence explaining the music you'll find for this mood
- top_moods: array of 3 {mood, category, confidence} alternatives

Return ONLY valid JSON. No markdown, no extra text."""

async def classify_mood(user_input: str) -> dict:
    """Send user text to Groq LLM and get structured mood classification."""
    response = await client.chat.completions.create(
        model="llama3-70b-8192",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_input}
        ],
        temperature=0.3,    # Low temp = consistent, predictable mood mapping
        max_tokens=300,
    )
    raw = response.choices[0].message.content.strip()
    return json.loads(raw)   # Raises JSONDecodeError on bad response — caller handles
```

- [ ] **Step 3: Create `backend/services/lastfm_service.py`**

```python
# lastfm_service.py — Validate mood-to-artist matches using Last.fm crowdsourced tags.
# Not on the critical path — called in background after playlist is returned.
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
```

- [ ] **Step 4: Smoke-test Groq (requires real API key in `.env`)**

```bash
cd backend
source venv/bin/activate
export $(cat .env | xargs)
python -c "
import asyncio
from services.groq_service import classify_mood
result = asyncio.run(classify_mood('I need to focus but im tired'))
print(result)
assert 'mood' in result and 'category' in result
print('Groq service OK')
"
```

Expected: JSON output with mood classification + `Groq service OK`

- [ ] **Step 5: Commit**

```bash
git add backend/services/ backend/.env.example
git commit -m "feat: Groq mood classifier and Last.fm mood tag validator"
```

---

### Task 9: Jamendo + YouTube Music Services + Mood Endpoint

**Files:**
- Create: `backend/services/jamendo_service.py`
- Create: `backend/services/youtube_service.py`
- Create: `backend/routers/mood.py`
- Create: `backend/routers/export.py`
- Create: `backend/routers/__init__.py`

- [ ] **Step 1: Create `backend/services/jamendo_service.py`**

```python
# jamendo_service.py — Fetch CC-licensed tracks from Jamendo for a mood.
# Free tier: 50,000 API calls/month. Cache aggressively to protect quota.
import os, httpx

JAMENDO_BASE = "https://api.jamendo.com/v3.0"

async def search_tracks(mood: str, seeds: list[str], limit: int = 20) -> list[dict]:
    """Search Jamendo for mood-appropriate tracks. Returns list of track dicts."""
    query = " ".join(seeds[:3])   # Use top 3 seeds to stay focused
    params = {
        "client_id": os.environ["JAMENDO_CLIENT_ID"],
        "format": "json",
        "limit": limit,
        "search": query,
        "audioformat": "mp32",    # 320kbps mp3 — best free quality
        "include": "musicinfo",   # Returns BPM, tags, etc.
        "groupby": "artist_id",   # Avoid 20 tracks from one artist
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
            "stream_url": t.get("audio"),          # Direct .mp3 URL
            "artwork_url": t.get("album_image"),
            "source": "jamendo",
            "energy": 0.3,                         # Jamendo doesn't expose energy; default low for chill moods
            "match_reason": f"CC-licensed, matched '{mood}' mood",
        })
    return tracks
```

- [ ] **Step 2: Create `backend/services/youtube_service.py`**

```python
# youtube_service.py — Search YouTube Data API for mood-appropriate videos.
# Quota: 10,000 units/day. 1 search = 100 units. Backend cache extends this ~100x.
import os, httpx

YT_BASE = "https://www.googleapis.com/youtube/v3"

async def search_tracks(mood: str, seeds: list[str], limit: int = 20) -> list[dict]:
    """Search YouTube for music videos matching the mood seeds."""
    query = f"{' '.join(seeds[:2])} music"
    params = {
        "part": "snippet",
        "q": query,
        "type": "video",
        "videoCategoryId": "10",   # Music category — filters non-music results
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
            "duration": 0,             # Duration requires a separate videos.list call — skip for now
            "stream_url": None,        # YouTube plays via video_id in YouTubePlayerKit
            "video_id": vid,
            "artwork_url": snippet["thumbnails"]["high"]["url"],
            "source": "youtube",
            "energy": 0.7,             # YouTube moods tend toward higher energy
            "match_reason": f"Matched '{mood}' mood via YouTube Music catalog",
        })
    return tracks
```

- [ ] **Step 3: Create `backend/routers/__init__.py`** (empty)

- [ ] **Step 4: Create `backend/routers/mood.py`**

```python
# mood.py — Single endpoint: classify mood + generate playlist in one round trip.
# Combining classification + playlist generation saves one round trip (important for cold starts).
import asyncio
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
    # 1. Check cache — avoid Groq + music API calls for repeated mood inputs
    cache_key = f"{req.input.lower().strip()}:{req.source_override or ''}"
    cached = playlist_cache.get(cache_key)
    if cached:
        return cached

    # 2. Classify mood via Groq LLM
    try:
        classification = await classify_mood(req.input)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Mood classification failed: {e}")

    mood = classification.get("mood", req.input.title())
    category = classification.get("category", "general")
    energy = classification.get("energy", 0.5)
    explanation = classification.get("explanation", "Music matched to your mood")
    top_moods = [MoodSuggestion(**m) for m in classification.get("top_moods", [])]

    # 3. Route to best source
    source = req.source_override or pick_source(category)
    seeds = mood_to_seeds(mood, category)

    # 4. Fetch tracks from chosen source (with Jamendo → YouTube fallback)
    raw_tracks = []
    if source == "jamendo":
        raw_tracks = await jamendo_search(mood, seeds)
        if len(raw_tracks) < 5:   # Jamendo returned too few — fall back
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

    # 5. Cache the result for 1 hour
    playlist_cache.set(cache_key, result)
    return result
```

- [ ] **Step 5: Create `backend/routers/export.py`**

```python
# export.py — Create playlists in Spotify or YouTube Music.
# Apple Music export is iOS-only (MusicKit) — NOT handled here.
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
        # Create playlist
        pl = await client.post(
            f"https://api.spotify.com/v1/users/{req.user_id}/playlists",
            headers=headers,
            json={"name": req.playlist_name, "public": False, "description": "Created by MeloMo"},
        )
        pl.raise_for_status()
        playlist_id = pl.json()["id"]

        # Search and add tracks
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
        playlist_id=playlist_id, matched_count=matched,
        total_count=len(req.tracks),
        playlist_url=f"https://open.spotify.com/playlist/{playlist_id}",
    )

async def _export_to_youtube_music(req: ExportRequest) -> ExportResponse:
    headers = {"Authorization": f"Bearer {req.auth_token}", "Content-Type": "application/json"}
    async with httpx.AsyncClient() as client:
        # Create playlist
        pl = await client.post(
            "https://www.googleapis.com/youtube/v3/playlists",
            headers=headers,
            params={"part": "snippet,status"},
            json={"snippet": {"title": req.playlist_name}, "status": {"privacyStatus": "private"}},
        )
        pl.raise_for_status()
        playlist_id = pl.json()["id"]

        # Add tracks that came from YouTube (have video_id)
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
        playlist_id=playlist_id, matched_count=matched,
        total_count=len(req.tracks),
        playlist_url=f"https://music.youtube.com/playlist?list={playlist_id}",
    )
```

- [ ] **Step 6: Wire routers into `backend/main.py`**

  Now that the router modules exist, add imports to `main.py`:

```python
# Add after existing imports in main.py:
from routers import mood, export

# Add before the @app.get("/health") line:
app.include_router(mood.router, prefix="/mood", tags=["mood"])
app.include_router(export.router, prefix="/playlist", tags=["export"])
```

- [ ] **Step 7: Run full backend and test mood endpoint**

```bash
cd backend
source venv/bin/activate
export $(cat .env | xargs)
uvicorn main:app --reload &
sleep 2

curl -X POST http://localhost:8000/mood/generate \
  -H "Content-Type: application/json" \
  -d '{"input": "I need to focus but im tired"}' | python -m json.tool

# Expected: JSON with mood, tracks[], source, explanation
```

- [ ] **Step 8: Commit**

```bash
git add backend/services/jamendo_service.py backend/services/youtube_service.py \
        backend/routers/ backend/main.py
git commit -m "feat: Jamendo + YouTube services, mood/generate + playlist/export endpoints, wire routers"
```

---

### Task 10: Deploy to Render

- [ ] **Step 1: Create Render account at render.com (free)**

- [ ] **Step 2: Create new Web Service**
  - Connect GitHub repo
  - Root directory: `backend`
  - Build command: `pip install -r requirements.txt`
  - Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
  - Instance type: Free

- [ ] **Step 3: Set environment variables in Render dashboard**

  Add all keys from `.env.example` with real values.

- [ ] **Step 4: Verify deployed health check**

```bash
curl https://your-app.onrender.com/health
# Expected: {"status":"ok"}
```

- [ ] **Step 5: Save the backend URL**

  Copy the Render URL (e.g. `https://melomo-backend.onrender.com`) — needed in `BackendClient.swift`.

- [ ] **Step 6: Commit deploy config**

```bash
git add backend/render.yaml
git commit -m "chore: Render deployment config for Python backend"
```

---

## Chunk 3: iOS Networking + Playback Engine

*Connects the iOS app to the backend and wires up Jamendo + YouTube playback.*

---

### Task 11: `BackendClient.swift` — API Client

**Files:**
- Create: `MeloMo/Managers/BackendClient.swift`

- [ ] **Step 1: Create the client**

```swift
// BackendClient.swift
// URLSession-based client for the Python backend. No Alamofire needed —
// URLSession handles async/await perfectly fine for our 2-endpoint API.
import Foundation

final class BackendClient {
    static let shared = BackendClient()

    // Replace with your Render URL after deploy. Debug builds hit localhost.
    #if DEBUG
    private let baseURL = URL(string: "http://localhost:8000")!
    #else
    private let baseURL = URL(string: "https://melomo-backend.onrender.com")!
    #endif

    // MARK: - Mood Generate

    func generatePlaylist(input: String, sourceOverride: String? = nil) async throws -> MoodGenerateResponse {
        var req = URLRequest(url: baseURL.appending(path: "/mood/generate"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15   // Render cold start can take ~3s; 15s is generous

        let body = MoodGenerateRequest(input: input, sourceOverride: sourceOverride)
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw BackendError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(MoodGenerateResponse.self, from: data)
    }

    // MARK: - Export

    func exportPlaylist(tracks: [TrackResponse], destination: String,
                        authToken: String, playlistName: String,
                        userId: String? = nil) async throws -> ExportResponse {
        var req = URLRequest(url: baseURL.appending(path: "/playlist/export"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30   // Exporting 25 tracks involves many API calls

        let body = ExportRequest(tracks: tracks, destination: destination,
                                 authToken: authToken, playlistName: playlistName, userId: userId)
        req.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(ExportResponse.self, from: data)
    }
}

// MARK: - Codable Request/Response DTOs (mirror backend models.py)

struct MoodGenerateRequest: Encodable {
    let input: String
    let sourceOverride: String?
    enum CodingKeys: String, CodingKey {
        case input
        case sourceOverride = "source_override"
    }
}

struct MoodGenerateResponse: Decodable {
    let mood: String
    let category: String
    let energy: Double
    let explanation: String
    let source: String
    let topMoods: [MoodSuggestion]
    let tracks: [TrackResponse]
    enum CodingKeys: String, CodingKey {
        case mood, category, energy, explanation, source
        case topMoods = "top_moods"
        case tracks
    }
}

struct MoodSuggestion: Decodable {
    let mood: String
    let category: String
    let confidence: Double
}

struct TrackResponse: Codable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: Double
    let streamURL: String?
    let videoId: String?
    let artworkURL: String?
    let source: String
    let energy: Double
    let matchReason: String
    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, duration, source, energy
        case streamURL = "stream_url"
        case videoId = "video_id"
        case artworkURL = "artwork_url"
        case matchReason = "match_reason"
    }

    func toMusicTrack() -> MusicTrack {
        MusicTrack(
            id: id, title: title, artist: artist, album: album,
            artworkURL: artworkURL.flatMap(URL.init),
            duration: duration, energy: energy,
            streamURL: streamURL.flatMap(URL.init),
            matchReason: matchReason
        )
    }
}

struct ExportRequest: Encodable {
    let tracks: [TrackResponse]
    let destination: String
    let authToken: String
    let playlistName: String
    let userId: String?
    enum CodingKeys: String, CodingKey {
        case tracks, destination
        case authToken = "auth_token"
        case playlistName = "playlist_name"
        case userId = "user_id"
    }
}

struct ExportResponse: Decodable {
    let playlistId: String
    let matchedCount: Int
    let totalCount: Int
    let playlistURL: String?
    enum CodingKeys: String, CodingKey {
        case playlistId = "playlist_id"
        case matchedCount = "matched_count"
        case totalCount = "total_count"
        case playlistURL = "playlist_url"
    }
}

enum BackendError: LocalizedError {
    case serverError(Int)
    var errorDescription: String? {
        if case .serverError(let code) = self { return "Backend returned HTTP \(code)" }
        return "Unknown backend error"
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MeloMo/Managers/BackendClient.swift
git commit -m "feat: BackendClient for mood/generate and playlist/export endpoints"
```

---

### Task 12: On-Device NL Fallback

**Files:**
- Create: `MeloMo/Managers/MoodFallbackClassifier.swift`

- [ ] **Step 1: Create the classifier**

```swift
// MoodFallbackClassifier.swift
// Used when the backend is cold (Render free tier sleeps after 15 min).
// Apple NaturalLanguage gives us positive/negative/neutral sentiment.
// We map that to a mood card + pre-select it for the user.
import NaturalLanguage

struct MoodFallbackClassifier {
    private static let tagger = NLTagger(tagSchemes: [.sentimentScore])

    // Simple keyword → mood title map. Not smart — just fast.
    private static let keywords: [(words: [String], mood: String)] = [
        (["focus", "study", "work", "concentrate", "productive"], "Focused"),
        (["tired", "sleepy", "slow", "low energy", "exhausted"],  "Calm"),
        (["happy", "joy", "excited", "great", "awesome"],         "Happy"),
        (["sad", "down", "blue", "cry", "heartbreak"],            "Sad"),
        (["angry", "frustrated", "stressed", "overwhelmed"],      "Stressed"),
        (["love", "romantic", "date", "cozy", "intimate"],        "Romantic"),
        (["party", "celebrate", "hype", "dance", "club"],         "Energetic"),
        (["chill", "relax", "vibe", "lofi", "easy"],              "Chill"),
    ]

    /// Returns the closest mood title for the input, or nil if nothing matches.
    static func classify(_ input: String) -> String? {
        let lower = input.lowercased()

        // Keyword pass first — more reliable than sentiment for specific moods
        for entry in keywords {
            if entry.words.contains(where: { lower.contains($0) }) {
                return entry.mood
            }
        }

        // Sentiment fallback: positive → Happy, negative → Sad, neutral → Chill
        tagger.string = input
        let (sentiment, _) = tagger.tag(at: input.startIndex, unit: .paragraph, scheme: .sentimentScore)
        guard let score = sentiment.flatMap({ Double($0.rawValue) }) else { return nil }

        if score > 0.3 { return "Happy" }
        if score < -0.3 { return "Sad" }
        return "Chill"
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MeloMo/Managers/MoodFallbackClassifier.swift
git commit -m "feat: on-device NL fallback classifier for backend cold start"
```

---

### Task 13: Jamendo + YouTube Playback Managers

**Files:**
- Create: `MeloMo/Managers/JamendoPlayer.swift`
- Create: `MeloMo/Managers/YouTubePlaybackManager.swift`

- [ ] **Step 1: Create `JamendoPlayer.swift`**

```swift
// JamendoPlayer.swift
// AVPlayer wrapper for Jamendo .mp3 stream URLs.
// Jamendo streams are direct URLs — no DRM, no token — AVPlayer handles them natively.
import AVFoundation
import Combine

@MainActor
final class JamendoPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: MusicTrack?

    private var player: AVPlayer?
    private var queue: [MusicTrack] = []
    private var currentIndex = 0

    func load(tracks: [MusicTrack]) {
        queue = tracks.filter { $0.streamURL != nil }
        currentIndex = 0
        playCurrentTrack()
    }

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func skipNext() {
        guard currentIndex + 1 < queue.count else { return }
        currentIndex += 1
        playCurrentTrack()
    }

    func skipPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        playCurrentTrack()
    }

    private func playCurrentTrack() {
        guard currentIndex < queue.count,
              let url = queue[currentIndex].streamURL else { return }
        currentTrack = queue[currentIndex]
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
    }
}
```

- [ ] **Step 2: Create `YouTubePlaybackManager.swift`**

```swift
// YouTubePlaybackManager.swift
// Coordinator between MusicController and YouTubePlayerKit.
// YouTubePlayerKit needs a SwiftUI view to render — this manager holds the video IDs
// and exposes controls. The actual YouTubePlayerView is embedded in NowPlayingView.
import YouTubePlayerKit
import Combine

@MainActor
final class YouTubePlaybackManager: ObservableObject {
    @Published var currentTrack: MusicTrack?
    @Published var isPlaying = false

    let player = YouTubePlayer(configuration: .init(autoPlay: true, showControls: false))

    private var queue: [MusicTrack] = []
    private var videoIds: [String] = []
    private var currentIndex = 0

    func load(tracks: [MusicTrack], videoIds: [String]) {
        self.queue = tracks
        self.videoIds = videoIds
        self.currentIndex = 0
        playCurrentTrack()
    }

    func skipNext() {
        guard currentIndex + 1 < videoIds.count else { return }
        currentIndex += 1
        playCurrentTrack()
    }

    func skipPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        playCurrentTrack()
    }

    func play()  { Task { try? await player.play() };  isPlaying = true }
    func pause() { Task { try? await player.pause() }; isPlaying = false }

    private func playCurrentTrack() {
        guard currentIndex < videoIds.count else { return }
        currentTrack = queue[safe: currentIndex]
        player.source = .video(id: videoIds[currentIndex])
        isPlaying = true
    }
}

// Safe subscript — avoids index-out-of-bounds crashes in player queues
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add MeloMo/Managers/JamendoPlayer.swift MeloMo/Managers/YouTubePlaybackManager.swift
git commit -m "feat: JamendoPlayer (AVPlayer) and YouTubePlaybackManager"
```

---

### Task 14: Refactor `MusicController` for New Architecture

**Files:**
- Modify: `MeloMo/Managers/MusicController.swift`

- [ ] **Step 1: Add `PlaybackSource` state and backend integration**

  Add these published properties to `MusicController`:

```swift
@Published var playbackSource: PlaybackSource = .youtube
@Published var jamendoPlayer = JamendoPlayer()
@Published var youtubeManager = YouTubePlaybackManager()
@Published var backendResponse: MoodGenerateResponse? = nil
@Published var moodSuggestions: [MoodSuggestion] = []
```

- [ ] **Step 2: Replace `generate(for:)` to call backend**

```swift
func generate(for mood: EnhancedMood) async {
    guard !isLoading else { Haptics.warning(); return }
    guard Date().timeIntervalSince(lastGenerationTime ?? .distantPast) >= 2 else {
        Haptics.warning(); return
    }

    currentMood = mood
    errorMessage = nil
    isLoading = true
    lastGenerationTime = Date()
    defer { isLoading = false }

    addToRecentMoods(mood)
    statistics.totalPlaylistsGenerated += 1
    statistics.lastUsedDate = Date()
    saveStatistics()
    Haptics.moodSelected()

    do {
        let response = try await BackendClient.shared.generatePlaylist(input: mood.title)
        backendResponse = response
        moodSuggestions = response.topMoods

        // rawValue matching fails for "youtube" → "Youtube" ≠ "YouTube".
        // Switch on lowercased string instead — explicit and compile-safe.
        let source: PlaybackSource
        switch response.source.lowercased() {
        case "jamendo":     source = .jamendo
        case "apple_music": source = .appleMusic
        default:            source = .youtube
        }
        playbackSource = source

        switch source {
        case .jamendo:
            let tracks = response.tracks.map { $0.toMusicTrack() }
            jamendoPlayer.load(tracks: tracks)
        case .youtube:
            let tracks = response.tracks.map { $0.toMusicTrack() }
            let videoIds = response.tracks.compactMap { $0.videoId }
            youtubeManager.load(tracks: tracks, videoIds: videoIds)
        case .appleMusic:
            // Existing Apple Music flow — unchanged
            let convertedMood = Mood(emoji: mood.emoji, imageName: mood.imageName,
                                     title: mood.title, description: mood.description,
                                     seeds: mood.seeds, energy: mood.energy,
                                     category: mood.category, popularity: mood.popularity)
            await generateAppleMusicPlaylist(mood: convertedMood)
        }
        Haptics.playlistGenerated()
    } catch {
        // On backend failure, try on-device fallback
        if let fallbackMood = MoodFallbackClassifier.classify(mood.title),
           let match = enhancedMoods.first(where: { $0.title == fallbackMood }) {
            errorMessage = "Using offline mode — backend unavailable"
            // Retry with a simpler Apple Music search as last resort
        } else {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}
```

- [ ] **Step 3: Build and verify no errors**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add MeloMo/Managers/MusicController.swift
git commit -m "refactor: MusicController integrates backend, JamendoPlayer, YouTubeManager"
```

---

## Chunk 4: iOS UI Overhaul

*Redesigns the visible app — Vibes tab, Now Playing, Library, Stats.*

---

### Task 15: Natural Language + Voice Input View

**Files:**
- Create: `MeloMo/Views/SubViews/NLMoodInputView.swift`
- Create: `MeloMo/Managers/SpeechManager.swift`

- [ ] **Step 1: Create `SpeechManager.swift`**

```swift
// SpeechManager.swift — Speech-to-text via iOS Speech framework.
// On-device by default (iOS 17+). No API key, no cost.
import Speech
import SwiftUI

@MainActor
final class SpeechManager: ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false

    private let recognizer = SFSpeechRecognizer(locale: .current)
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()

    func startListening() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            Task { @MainActor in self?.beginSession() }
        }
    }

    func stopListening() {
        engine.stop()
        request?.endAudio()
        isListening = false
    }

    private func beginSession() {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let node = engine.inputNode
        let fmt  = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in
            request.append(buf)
        }

        try? engine.start()
        isListening = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let text = result?.bestTranscription.formattedString {
                self?.transcript = text
            }
            if error != nil || result?.isFinal == true {
                self?.stopListening()
            }
        }
    }
}
```

- [ ] **Step 2: Create `NLMoodInputView.swift`**

```swift
// NLMoodInputView.swift — "How are you feeling?" input bar with voice support.
// Sends text to backend; shows top mood suggestions for user to confirm.
import SwiftUI
import FontAwesome

struct NLMoodInputView: View {
    @EnvironmentObject private var musicController: MusicController
    @StateObject private var speech = SpeechManager()
    @State private var inputText = ""
    @State private var isLoading = false
    @FocusState private var isFocused: Bool

    var onMoodSelected: (EnhancedMood) -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Input row
            HStack(spacing: 10) {
                TextField("How are you feeling?", text: $inputText)
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .onSubmit { submitIfNeeded() }

                // Voice button
                Button(action: toggleVoice) {
                    Text(speech.isListening ? Icons.close : Icons.mic)
                        .font(Font.fontAwesome(ofSize: 18, style: .solid))
                        .foregroundColor(speech.isListening ? .red : .gray)
                }

                // Submit button
                if !inputText.isEmpty {
                    Button(action: submitIfNeeded) {
                        Text(Icons.search)
                            .font(Font.fontAwesome(ofSize: 18, style: .solid))
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Mood suggestions
            if !musicController.moodSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(musicController.moodSuggestions, id: \.mood) { suggestion in
                            MoodSuggestionRow(suggestion: suggestion) {
                                if let match = enhancedMoods.first(where: {
                                    $0.title.lowercased() == suggestion.mood.lowercased()
                                }) {
                                    onMoodSelected(match)
                                    inputText = ""
                                    musicController.moodSuggestions = []
                                    isFocused = false
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .onChange(of: speech.transcript) { _, new in
            if !new.isEmpty { inputText = new }
        }
    }

    private func submitIfNeeded() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        // Try on-device fallback first for instant response while backend wakes
        if let fallback = MoodFallbackClassifier.classify(inputText),
           let match = enhancedMoods.first(where: { $0.title == fallback }) {
            onMoodSelected(match)
        }
        // Also fire backend call — its result will update moodSuggestions
        Task { await musicController.generate(forText: inputText) }
        isFocused = false
    }

    private func toggleVoice() {
        speech.isListening ? speech.stopListening() : speech.startListening()
    }
}
```

- [ ] **Step 3: Add `generate(forText:)` to `MusicController`**

```swift
// In MusicController.swift — NL text path (vs mood card path)
func generate(forText input: String) async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }
    do {
        let response = try await BackendClient.shared.generatePlaylist(input: input)
        backendResponse = response
        moodSuggestions = response.topMoods
    } catch {
        // Silent fallback — on-device classifier already handled the immediate response
        moodSuggestions = []
    }
}
```

- [ ] **Step 4: Add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` to `Info.plist`**

  In Xcode: Add two keys to `MeloMo/Info.plist`:
  - `NSMicrophoneUsageDescription` → `"MeloMo needs your mic to hear your mood"`
  - `NSSpeechRecognitionUsageDescription` → `"MeloMo uses speech to understand your mood"`

- [ ] **Step 5: Commit**

```bash
git add MeloMo/Managers/SpeechManager.swift MeloMo/Views/SubViews/NLMoodInputView.swift \
        MeloMo/Managers/MusicController.swift MeloMo/Info.plist
git commit -m "feat: natural language + voice mood input with on-device fallback"
```

---

### Task 16: Redesign `EnhancedVibesView` + Category Pills

**Files:**
- Modify: `MeloMo/Views/EnhancedVibesView.swift`
- Create: `MeloMo/Views/SubViews/MoodSuggestionRow.swift`

- [ ] **Step 1: Create `MoodSuggestionRow.swift`**

```swift
// MoodSuggestionRow.swift — A pill chip showing a mood suggestion from NL classification.
import SwiftUI

struct MoodSuggestionRow: View {
    let suggestion: MoodSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(suggestion.mood)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(String(format: "%.0f%%", suggestion.confidence * 100))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
        }
        .foregroundColor(.white)
    }
}
```

- [ ] **Step 2: Update `EnhancedVibesView` — add NL input bar at top**

  At the top of the `ScrollView` in `EnhancedVibesView.body`, add:

```swift
// Above the category filter pills:
NLMoodInputView(onMoodSelected: { mood in
    Task { await musicController.generate(for: mood) }
})
.environmentObject(musicController)
.padding(.horizontal, 16)
.padding(.top, 8)
```

- [ ] **Step 3: Update category filter pills to 8 categories with FA icons**

  Replace existing category filter with:

```swift
// Using FontAwesome enum cases directly — rawValue is a Unicode char, NOT a CSS name.
// FontAwesome(rawValue: "bolt") would always return nil; enum cases are the only safe API.
private let categories: [(MoodCategory?, String, FontAwesome)] = [
    (nil,          "All",       .music),
    (.energetic,   "Energetic", .bolt),
    (.chill,       "Chill",     .leaf),
    (.focused,     "Focus",     .brain),
    (.emotional,   "Emotional", .heart),
    (.romantic,    "Romantic",  .heartPulse),
    (.social,      "Social",    .peopleGroup),
    (.magical,     "Magical",   .wandMagicSparkles),
    (.melancholy,  "Melancholy",.cloudRain),
]

// Render pills:
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 10) {
        ForEach(categories, id: \.1) { (category, label, icon) in
            Button(action: { selectedCategory = category }) {
                HStack(spacing: 5) {
                    Text(String.fontAwesomeIcon(name: icon))
                        .font(Font.fontAwesome(ofSize: 12, style: .solid))
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selectedCategory == category
                    ? Color.yellow.opacity(0.8)
                    : Color.white.opacity(0.1))
                .foregroundColor(selectedCategory == category ? .black : .white)
                .clipShape(Capsule())
            }
        }
    }
    .padding(.horizontal, 16)
}
```

- [ ] **Step 4: Build and verify UI renders**

  Run in Simulator (iPhone 15 Pro). Check NL bar, pills, mood cards render correctly.

- [ ] **Step 5: Commit**

```bash
git add MeloMo/Views/EnhancedVibesView.swift MeloMo/Views/SubViews/MoodSuggestionRow.swift
git commit -m "feat: NL input bar + 8-category filter pills in Vibes tab"
```

---

### Task 17: Now Playing Screen

**Files:**
- Create: `MeloMo/Views/NowPlayingView.swift`
- Create: `MeloMo/Views/SubViews/WhyThisSongView.swift`
- Create: `MeloMo/Views/SubViews/ExportSheetView.swift`

- [ ] **Step 1: Create `WhyThisSongView.swift`**

```swift
// WhyThisSongView.swift — Expandable match explanation panel.
import SwiftUI

struct WhyThisSongView: View {
    let reason: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack {
                    Text(Icons.info)
                        .font(Font.fontAwesome(ofSize: 14, style: .solid))
                    Text("Why this song?")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            if isExpanded {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Create `ExportSheetView.swift`**

```swift
// ExportSheetView.swift — Bottom sheet for cloning playlist to streaming apps.
import SwiftUI
import FontAwesome

struct ExportSheetView: View {
    @EnvironmentObject private var musicController: MusicController
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportResult: String? = nil

    let playlistName: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Clone to Your App")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.top, 24)

                Text("Your playlist will appear in the app you choose.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    ExportDestinationRow(
                        icon: Icons.spotify, iconStyle: .brands,
                        name: "Spotify", color: Color(red: 0.11, green: 0.73, blue: 0.33)
                    ) { await export(to: "spotify") }

                    ExportDestinationRow(
                        icon: Icons.apple, iconStyle: .brands,
                        name: "Apple Music", color: .pink
                    ) { await exportAppleMusic() }

                    ExportDestinationRow(
                        icon: Icons.youtube, iconStyle: .brands,
                        name: "YouTube Music", color: .red
                    ) { await export(to: "youtube_music") }
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)

                if let result = exportResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.top, 16)
                }

                Spacer()
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.12))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
        }
    }

    private func export(to destination: String) async {
        // Spotify/YouTube Music export wired to ExportManager in Task 19.
        // Shows in-progress state now; result shown after Task 19 is complete.
        isExporting = true
        defer { isExporting = false }
        exportResult = "Preparing export…"
    }

    private func exportAppleMusic() async {
        // Apple Music export is on-device (MusicKit) — wired to ExportManager in Task 19.
        // Until then, guide the user without exposing internal task notes.
        exportResult = "Apple Music: ensure you're signed in to the Music app, then try again."
    }
}

struct ExportDestinationRow: View {
    let icon: String
    let iconStyle: FontAwesomeStyle
    let name: String
    let color: Color
    let action: () async -> Void

    var body: some View {
        Button(action: { Task { await action() } }) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(Font.fontAwesome(ofSize: 22, style: iconStyle))
                    .foregroundColor(color)
                    .frame(width: 36)
                Text(name)
                    .font(.body).fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
```

- [ ] **Step 3: Create `NowPlayingView.swift`**

```swift
// NowPlayingView.swift — Full-screen now playing experience.
// Hosts the YouTubePlayerView (invisible behind artwork) or shows artwork for Jamendo/Apple Music.
import SwiftUI
import YouTubePlayerKit
import FontAwesome

struct NowPlayingView: View {
    @EnvironmentObject private var musicController: MusicController
    @State private var showExportSheet = false

    private var currentTrack: MusicTrack? {
        switch musicController.playbackSource {
        case .jamendo:    return musicController.jamendoPlayer.currentTrack
        case .youtube:    return musicController.youtubeManager.currentTrack
        case .appleMusic: return musicController.currentPlayingTrack
        }
    }

    var body: some View {
        ZStack {
            // Cinematic background
            Color(red: 0.04, green: 0.04, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                // YouTube player (hidden behind artwork; drives audio)
                if musicController.playbackSource == .youtube {
                    YouTubePlayerView(musicController.youtubeManager.player)
                        .frame(width: 1, height: 1)   // 1x1 — present in hierarchy but invisible
                        .opacity(0.001)
                }

                Spacer()

                // Artwork
                artworkSection

                // Track info
                trackInfoSection

                // Controls
                controlsSection

                // Why this song
                if let reason = currentTrack?.matchReason {
                    WhyThisSongView(reason: reason)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                // Clone button
                Button(action: { showExportSheet = true }) {
                    HStack(spacing: 8) {
                        Text(Icons.export)
                            .font(Font.fontAwesome(ofSize: 16, style: .solid))
                        Text("Clone to your app")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheetView(playlistName: "\(currentTrack?.mood ?? "My") Playlist")
                .environmentObject(musicController)
        }
    }

    private var artworkSection: some View {
        AsyncImage(url: currentTrack?.artworkURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.white.opacity(0.08)
        }
        .frame(width: 260, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.5), radius: 30)
        .padding(.bottom, 28)
    }

    private var trackInfoSection: some View {
        VStack(spacing: 4) {
            Text(currentTrack?.title ?? "Now Playing")
                .font(.title3).fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            Text(currentTrack?.artist ?? "")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 24)
    }

    private var controlsSection: some View {
        HStack(spacing: 44) {
            controlButton(icon: Icons.skipPrev) { skipPrevious() }
            controlButton(icon: isPlaying ? Icons.pause : Icons.play, size: 44) { togglePlay() }
            controlButton(icon: Icons.skipNext) { skipNext() }
        }
        .padding(.bottom, 16)
    }

    private func controlButton(icon: String, size: CGFloat = 28, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(icon)
                .font(Font.fontAwesome(ofSize: size, style: .solid))
                .foregroundColor(.white)
        }
    }

    private var isPlaying: Bool {
        switch musicController.playbackSource {
        case .jamendo:    return musicController.jamendoPlayer.isPlaying
        case .youtube:    return musicController.youtubeManager.isPlaying
        case .appleMusic: return musicController.isPlaying
        }
    }

    private func togglePlay() {
        switch musicController.playbackSource {
        case .jamendo:
            isPlaying ? musicController.jamendoPlayer.pause() : musicController.jamendoPlayer.play()
        case .youtube:
            isPlaying ? musicController.youtubeManager.pause() : musicController.youtubeManager.play()
        case .appleMusic:
            Task { isPlaying
                ? try? await ApplicationMusicPlayer.shared.pause()
                : try? await ApplicationMusicPlayer.shared.play()
            }
        }
    }

    private func skipNext() {
        switch musicController.playbackSource {
        case .jamendo:    musicController.jamendoPlayer.skipNext()
        case .youtube:    musicController.youtubeManager.skipNext()
        case .appleMusic: Task { await musicController.skipToNext() }
        }
    }

    private func skipPrevious() {
        switch musicController.playbackSource {
        case .jamendo:    musicController.jamendoPlayer.skipPrevious()
        case .youtube:    musicController.youtubeManager.skipPrevious()
        case .appleMusic: Task { await musicController.skipToPrevious() }
        }
    }
}
```

- [ ] **Step 4: Build and verify in Simulator**

  Cmd+R. Navigate to a mood, verify Now Playing shows. Check FA icons render.

- [ ] **Step 5: Commit**

```bash
git add MeloMo/Views/NowPlayingView.swift \
        MeloMo/Views/SubViews/WhyThisSongView.swift \
        MeloMo/Views/SubViews/ExportSheetView.swift
git commit -m "feat: NowPlayingView with FA controls, WhyThisSong, ExportSheet skeleton"
```

---

### Task 18: Library + Stats Tabs + ContentView Update

**Files:**
- Create: `MeloMo/Views/LibraryView.swift`
- Create: `MeloMo/Views/SubViews/StreakBannerView.swift`
- Modify: `MeloMo/Views/SubViews/StatsView.swift`
- Modify: `MeloMo/Views/ContentView.swift`

- [ ] **Step 1: Create `LibraryView.swift`**

```swift
// LibraryView.swift — Saved and exported playlists.
import SwiftUI
import SwiftData
import FontAwesome

struct LibraryView: View {
    @Query(sort: \SavedPlaylist.createdAt, order: .reverse) private var playlists: [SavedPlaylist]
    @EnvironmentObject private var musicController: MusicController

    var body: some View {
        NavigationStack {
            ScrollView {
                if playlists.isEmpty {
                    VStack(spacing: 16) {
                        Text(Icons.library)
                            .font(Font.fontAwesome(ofSize: 48, style: .solid))
                            .foregroundColor(.gray)
                        Text("No saved playlists yet")
                            .foregroundColor(.gray)
                        Text("Generate a playlist and save it to your library")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(playlists) { playlist in
                            PlaylistCard(playlist: playlist)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(red: 0.04, green: 0.04, blue: 0.08))
        }
    }
}

struct PlaylistCard: View {
    let playlist: SavedPlaylist

    var body: some View {
        HStack(spacing: 14) {
            Text(playlist.moodEmoji)
                .font(.title)
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("\(playlist.tracks.count) songs · \(playlist.moodTitle)")
                    .font(.caption)
                    .foregroundColor(.gray)
                // Export badges
                HStack(spacing: 4) {
                    ForEach(playlist.exportedTo, id: \.self) { dest in
                        // Three-way match — "apple_music" would render YouTube icon otherwise
                        let icon = dest == "spotify" ? Icons.spotify
                                 : dest == "apple_music" ? Icons.apple
                                 : Icons.youtube
                        Text(icon)
                            .font(Font.fontAwesome(ofSize: 10, style: .brands))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

- [ ] **Step 2: Create `StreakBannerView.swift`**

```swift
// StreakBannerView.swift — Shows current consecutive-day streak.
import SwiftUI
import FontAwesome

struct StreakBannerView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(Icons.fire)
                .font(Font.fontAwesome(ofSize: 28, style: .solid))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(.title3).fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Keep picking your daily mood")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.orange.opacity(0.2), .clear],
                           startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

- [ ] **Step 3: Update `StatsView.swift` with real data**

  Replace the placeholder content with:

```swift
// StatsView.swift — Real mood analytics from AppStatistics + streak tracking.
struct StatsView: View {
    @EnvironmentObject private var musicController: MusicController

    // Streak is stored in UserDefaults — key: "moodStreak"
    private var streak: Int {
        UserDefaults.standard.integer(forKey: "moodStreak")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StreakBannerView(streak: streak)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Playlists", value: "\(musicController.statistics.totalPlaylistsGenerated)", icon: Icons.vibes)
                        StatCard(title: "Fav Mood", value: musicController.favoriteMoods.first?.title ?? "—", icon: Icons.heart)
                        StatCard(title: "Provider", value: musicController.statistics.mostUsedProvider.rawValue, icon: Icons.stats)
                        StatCard(title: "Recents", value: "\(musicController.recentMoods.count)", icon: Icons.library)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("Stats")
            .background(Color(red: 0.04, green: 0.04, blue: 0.08))
        }
    }
}
```

- [ ] **Step 4: Update `ContentView.swift` with FA tab icons and new tabs**

```swift
TabView(selection: $selectedTab) {
    EnhancedVibesView(...)
        .tabItem {
            Text(Icons.vibes).font(Font.fontAwesome(ofSize: 20, style: .solid))
            Text("Vibes")
        }
        .tag(0)

    LibraryView()
        .environmentObject(musicController)
        .tabItem {
            Text(Icons.library).font(Font.fontAwesome(ofSize: 20, style: .solid))
            Text("Library")
        }
        .tag(1)

    StatsView()
        .environmentObject(musicController)
        .tabItem {
            Text(Icons.stats).font(Font.fontAwesome(ofSize: 20, style: .solid))
            Text("Stats")
        }
        .tag(2)

    SettingsView()
        .tabItem {
            Text(Icons.gear).font(Font.fontAwesome(ofSize: 20, style: .solid))
            Text("Profile")
        }
        .tag(3)
}
```

- [ ] **Step 5: Build and test in Simulator**

  Cmd+R. All 4 tabs should show. FA icons should render in tab bar.

- [ ] **Step 6: Commit**

```bash
git add MeloMo/Views/LibraryView.swift MeloMo/Views/SubViews/StreakBannerView.swift \
        MeloMo/Views/SubViews/StatsView.swift MeloMo/Views/ContentView.swift
git commit -m "feat: Library tab, StreakBanner, real Stats, FA tab icons in ContentView"
```

---

## Chunk 5: Export Engine

*Wires up the actual Spotify, Apple Music, and YouTube Music playlist creation.*

---

### Task 19: `ExportManager` + Apple Music Export

**Files:**
- Create: `MeloMo/Managers/ExportManager.swift`

- [ ] **Step 1: Create `ExportManager.swift`**

```swift
// ExportManager.swift — Orchestrates playlist export to all three services.
// Spotify + YouTube Music → backend. Apple Music → on-device MusicKit.
// Why split: MusicKit auth token is device-bound, can't be forwarded to server.
import Foundation
import MusicKit

@MainActor
final class ExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var lastResult: ExportResult? = nil

    struct ExportResult {
        let destination: String
        let matched: Int
        let total: Int
        let playlistURL: String?
        var summary: String { "\(matched) of \(total) songs added ✓" }
    }

    // MARK: - Apple Music (on-device, no backend)

    func exportToAppleMusic(tracks: [TrackResponse], playlistName: String) async throws {
        isExporting = true
        defer { isExporting = false }

        // Create playlist in user's library
        let playlist = try await MusicLibrary.shared.createPlaylist(
            name: playlistName,
            description: "Created by MeloMo",
            items: []
        )

        // Search Apple Music catalog for each track and add
        var matched = 0
        for track in tracks {
            var req = MusicCatalogSearchRequest(term: "\(track.title) \(track.artist)", types: [Song.self])
            req.limit = 1
            if let song = try? await req.response().songs.first {
                try? await MusicLibrary.shared.add(song, to: playlist)
                matched += 1
            }
        }

        lastResult = ExportResult(
            destination: "Apple Music",
            matched: matched, total: tracks.count, playlistURL: nil
        )
    }

    // MARK: - Spotify (via backend)

    func exportToSpotify(tracks: [TrackResponse], playlistName: String,
                         accessToken: String, userId: String) async throws {
        isExporting = true
        defer { isExporting = false }

        let response = try await BackendClient.shared.exportPlaylist(
            tracks: tracks, destination: "spotify",
            authToken: accessToken, playlistName: playlistName, userId: userId
        )
        lastResult = ExportResult(
            destination: "Spotify",
            matched: response.matchedCount, total: response.totalCount,
            playlistURL: response.playlistURL
        )
    }

    // MARK: - YouTube Music (via backend)

    func exportToYouTubeMusic(tracks: [TrackResponse], playlistName: String,
                               accessToken: String) async throws {
        isExporting = true
        defer { isExporting = false }

        let response = try await BackendClient.shared.exportPlaylist(
            tracks: tracks, destination: "youtube_music",
            authToken: accessToken, playlistName: playlistName
        )
        lastResult = ExportResult(
            destination: "YouTube Music",
            matched: response.matchedCount, total: response.totalCount,
            playlistURL: response.playlistURL
        )
    }
}
```

- [ ] **Step 2: Wire `ExportManager` into `ExportSheetView`**

  Add `@StateObject private var exportManager = ExportManager()` and `@EnvironmentObject private var musicController: MusicController` to `ExportSheetView`. Tracks come from `musicController.backendResponse?.tracks ?? []`.

  Replace the placeholder methods with:

```swift
// Replace export(to:) in ExportSheetView:
private func export(to destination: String) async {
    guard let tracks = musicController.backendResponse?.tracks, !tracks.isEmpty else {
        exportResult = "No tracks to export — generate a playlist first"
        return
    }
    // Spotify requires userId from OAuth; for v1, user must paste their Spotify user ID.
    // Full OAuth flow is a future enhancement.
    do {
        if destination == "spotify" {
            try await exportManager.exportToSpotify(
                tracks: tracks, playlistName: playlistName,
                accessToken: "YOUR_SPOTIFY_TOKEN", userId: "YOUR_SPOTIFY_USER_ID"
            )
        } else {
            try await exportManager.exportToYouTubeMusic(
                tracks: tracks, playlistName: playlistName,
                accessToken: "YOUR_YOUTUBE_TOKEN"
            )
        }
        exportResult = exportManager.lastResult?.summary ?? "Export complete"
    } catch {
        exportResult = "Export failed: \(error.localizedDescription)"
    }
}

// Replace exportAppleMusic() in ExportSheetView:
private func exportAppleMusic() async {
    guard let tracks = musicController.backendResponse?.tracks, !tracks.isEmpty else {
        exportResult = "No tracks to export — generate a playlist first"
        return
    }
    do {
        try await exportManager.exportToAppleMusic(tracks: tracks, playlistName: playlistName)
        exportResult = exportManager.lastResult?.summary ?? "Added to Apple Music"
    } catch {
        exportResult = "Apple Music: ensure you're signed in to the Music app, then try again."
    }
}
```

- [ ] **Step 3: Add `ExportManager` as environment object in `MeloMoApp.swift`**

```swift
// In MeloMoApp.swift — inject ExportManager
@StateObject private var exportManager = ExportManager()

// In WindowGroup body:
.environmentObject(exportManager)
```

- [ ] **Step 4: Save exported playlist to SwiftData Library**

  After a successful export in `ExportManager`, if there's a matching `SavedPlaylist`, append the destination to its `exportedTo` array. This shows the badge in the Library tab.

- [ ] **Step 5: Commit**

```bash
git add MeloMo/Managers/ExportManager.swift MeloMo/Views/SubViews/ExportSheetView.swift \
        MeloMo/Core/MeloMoApp.swift
git commit -m "feat: ExportManager for Apple Music (MusicKit), Spotify + YouTube Music (backend)"
```

---

## Chunk 6: Daily Engagement + Challenges

*Streak tracking, smart notifications, real challenge content.*

---

### Task 20: Mood Streak Tracking + Daily Notifications

**Files:**
- Create: `MeloMo/Managers/StreakManager.swift`

- [ ] **Step 1: Create `StreakManager.swift`**

```swift
// StreakManager.swift — Tracks consecutive daily mood selections and schedules notifications.
// All local — no server needed. UserDefaults stores last-used date + streak count.
import Foundation
import UserNotifications

struct StreakManager {
    private static let defaults = UserDefaults.standard
    private static let streakKey = "moodStreak"
    private static let lastDateKey = "moodStreakLastDate"

    /// Call this every time user picks a mood or generates a playlist.
    static func recordActivity() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = defaults.object(forKey: lastDateKey) as? Date ?? .distantPast
        let lastDay = Calendar.current.startOfDay(for: lastDate)

        if lastDay == today { return }  // Already recorded today

        let daysSinceLast = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        let currentStreak = defaults.integer(forKey: streakKey)

        let newStreak = daysSinceLast == 1 ? currentStreak + 1 : 1  // Reset if gap > 1 day
        defaults.set(newStreak, forKey: streakKey)
        defaults.set(Date(), forKey: lastDateKey)
    }

    static var current: Int { defaults.integer(forKey: streakKey) }

    /// Schedule a daily mood reminder. Call once on first launch.
    static func scheduleDailyNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "What's your vibe today?"
            content.body = "Pick a mood and let MeloMo find your perfect playlist 🎵"
            content.sound = .default

            // One daily trigger at 9 AM. To differentiate weekdays/weekends you'd need
            // 7 separate triggers (one per weekday value) — overkill for v1.
            // 9 AM is a reasonable middle ground between the "8 weekday / 10 weekend" plan.
            var comps = DateComponents()
            comps.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(
                identifier: "daily-mood",
                content: content, trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }
}
```

- [ ] **Step 2: Call `StreakManager.recordActivity()` in `MusicController.generate(for:)`**

  Add after `addToRecentMoods(mood)`:
```swift
StreakManager.recordActivity()
```

- [ ] **Step 3: Call `StreakManager.scheduleDailyNotification()` on first launch**

  In `MeloMoApp.swift`, in `onAppear`:
```swift
.onAppear {
    if !UserDefaults.standard.bool(forKey: "notificationsScheduled") {
        StreakManager.scheduleDailyNotification()
        UserDefaults.standard.set(true, forKey: "notificationsScheduled")
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add MeloMo/Managers/StreakManager.swift MeloMo/Managers/MusicController.swift \
        MeloMo/Core/MeloMoApp.swift
git commit -m "feat: daily mood streak tracking + smart local push notifications"
```

---

### Task 21: Real Challenges Content

**Files:**
- Modify: `MeloMo/Views/SubViews/ChallengesView.swift`

- [ ] **Step 1: Replace stubs with real data-driven challenges**

```swift
// ChallengesView.swift — Real weekly challenges driven by actual usage data.
struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let progress: Int
    let goal: Int
    var isComplete: Bool { progress >= goal }
}

struct ChallengesView: View {
    @EnvironmentObject private var musicController: MusicController

    private var challenges: [Challenge] {
        [
            Challenge(title: "Mood Explorer",
                      description: "Try 3 different mood categories this week",
                      icon: Icons.vibes,
                      progress: min(Set(musicController.recentMoods.map(\.category)).count, 3),
                      goal: 3),
            Challenge(title: "Daily Listener",
                      description: "Pick your mood 7 days in a row",
                      icon: Icons.fire,
                      progress: min(StreakManager.current, 7),
                      goal: 7),
            Challenge(title: "Export Master",
                      description: "Clone a playlist to one of your apps",
                      icon: Icons.export,
                      progress: UserDefaults.standard.integer(forKey: "totalExports") > 0 ? 1 : 0,
                      goal: 1),
            Challenge(title: "Playlist Pro",
                      description: "Generate 10 playlists",
                      icon: Icons.trophy,
                      progress: min(musicController.statistics.totalPlaylistsGenerated, 10),
                      goal: 10),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(challenges) { challenge in
                        ChallengeCard(challenge: challenge)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("Challenges")
            .background(Color(red: 0.04, green: 0.04, blue: 0.08))
        }
    }
}

struct ChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 14) {
            Text(challenge.icon)
                .font(Font.fontAwesome(ofSize: 22, style: .solid))
                .foregroundColor(challenge.isComplete ? .yellow : .gray)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(challenge.description)
                    .font(.caption).foregroundColor(.gray)

                ProgressView(value: Double(challenge.progress), total: Double(challenge.goal))
                    .tint(challenge.isComplete ? .yellow : .blue)
            }

            if challenge.isComplete {
                Text(Icons.trophy)
                    .font(Font.fontAwesome(ofSize: 18, style: .solid))
                    .foregroundColor(.yellow)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MeloMo/Views/SubViews/ChallengesView.swift
git commit -m "feat: real challenge cards with progress tracking (mood explorer, streak, export, pro)"
```

---

### Task 22: Final Integration + Smoke Test

- [ ] **Step 1: Full build with no errors or warnings**

  Cmd+B. Expected: Build Succeeded, 0 errors.

- [ ] **Step 2: Manual smoke test on device or Simulator**

  - [ ] Tap a mood card → playlist generates → Now Playing appears
  - [ ] Type in NL bar → mood suggestions appear → tap suggestion → music plays
  - [ ] Tap mic → speak "I need to focus" → transcribes → playlist plays
  - [ ] In Now Playing, tap "Why this song?" → reason expands
  - [ ] Tap "Clone to your app" → export sheet appears with 3 options
  - [ ] Library tab shows saved playlists (after saving one)
  - [ ] Stats tab shows streak counter and playlist count
  - [ ] Challenges tab shows 4 real challenges with progress bars
  - [ ] FA icons render in all tabs, buttons, and cards

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: MeloMo v2 — AI mood input, free playback, playlist export, streaks, challenges"
```

---

## Summary

| Chunk | Tasks | What Ships |
|-------|-------|-----------|
| 1 — Foundation | 1–5 | FontAwesome, PlaybackSource, SwiftData, bug fixes |
| 2 — Backend | 6–10 | FastAPI on Render, Groq + Jamendo + YouTube, deployed |
| 3 — Networking + Playback | 11–14 | BackendClient, JamendoPlayer, YouTubeManager, MusicController refactor |
| 4 — UI Overhaul | 15–18 | NL input, voice, Now Playing, Library, Stats, FA tab icons |
| 5 — Export | 19 | Apple Music (MusicKit), Spotify + YouTube Music (backend) |
| 6 — Engagement | 20–22 | Streaks, notifications, real challenges, smoke test |
