# MeloMo Enhancement Design Spec
**Date:** 2026-03-22
**Approach:** Approach 2 — iOS App + Lightweight Python Backend
**Status:** Approved by user — v2 (reviewer issues addressed)

---

## 1. Overview

MeloMo is a free iOS mood-based playlist app. Users select their mood (via card picker, natural language text, or voice), and the app automatically generates and plays a playlist — for free, no subscription required. Users can also export/clone any playlist directly into Spotify, Apple Music, or YouTube Music as a saved playlist.

**The core promise:**
> Pick your mood. Music plays instantly. Free forever. Export anywhere.

**What makes it worth downloading:**
- Genuinely free in-app listening (YouTube + Jamendo, auto-selected by mood)
- Natural language input: "I feel like a foggy Tuesday morning" → playlist
- Export/clone playlist to Spotify, Apple Music, or YouTube Music with one tap
- AI-powered source routing — Focus moods get distraction-free Jamendo instrumentals; Hype moods get YouTube's mainstream catalog
- Playlist explanations: "Low tempo, no lyrics, minor key — matched your Focus mood"

---

## 2. Architecture

### 2.1 System Components

```
┌─────────────────────────────────────────────┐
│              MeloMo iOS App (Swift/SwiftUI)  │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Mood    │  │ Playback │  │  Export  │  │
│  │  Input   │  │  Engine  │  │  Engine  │  │
│  │(NL/Voice/│  │(YouTube/ │  │(Spotify/ │  │
│  │  Picker) │  │ Jamendo/ │  │Apple Mus.│  │
│  │          │  │Apple Mus)│  │/ YT Music│  │
│  └────┬─────┘  └─────▲────┘  └──────────┘  │
│       │              │                      │
└───────┼──────────────┼──────────────────────┘
        │ mood text    │ playlist + source
        ▼              │
┌───────────────────────────────────────────┐
│   MeloMo Python Backend (Render, free)    │
│                                           │
│  Groq LLM (free) → mood classification   │
│  Last.fm API (free) → artist mood tags   │
│  Smart router → picks best source        │
│  Cache layer → protects API quotas       │
│  Jamendo API (free) → free track search  │
│  YouTube Data API (free) → mainstream    │
└───────────────────────────────────────────┘
```

### 2.2 Data Flow

1. User inputs mood (text / voice / card tap)
2. iOS app sends mood text to Python backend via single `POST /mood/generate` call
3. Backend runs Groq LLM to classify mood → category + energy level + intent
4. Backend queries the right source (Jamendo or YouTube) based on routing rules
5. Backend validates results against Last.fm mood tags
6. Backend returns playlist (track list with stream URLs + explanation text) in one response
7. iOS app plays tracks via appropriate player:
   - Jamendo tracks → native `AVPlayer` (direct stream URL from backend)
   - YouTube tracks → `YouTubePlayerKit` (WKWebView embed, ads shown as YouTube intends)
   - Apple Music → `MusicKit` / `ApplicationMusicPlayer` (existing, unchanged)
8. User can clone the playlist to Spotify (backend), Apple Music (on-device MusicKit), or YouTube Music (backend)

**Note:** Apple Music export is always handled on-device via MusicKit. It never goes through the Python backend because the MusicKit auth token lives on-device and cannot be forwarded to a server.

---

## 3. Features

### 3.1 Mood Input (Three Paths)

**Card Picker (existing, redesigned)**
- 30+ mood cards in a cinematic dark grid
- Category filter pills: **Energetic | Chill | Focused | Emotional | Romantic | Social | Magical | Melancholy**
  - These map directly to the existing `MoodCategory` enum cases: `.energetic`, `.chill`, `.focused`, `.emotional`, `.romantic`, `.social`, `.magical`, `.melancholy`
  - `.relaxed` and `.general` moods are surfaced under Chill and the unfiltered "All" state respectively — no cards are dropped
- Tap a card → instantly triggers playlist generation

**Natural Language Input (new)**
- Search bar at top of Vibes tab: "How are you feeling?"
- User types freely: "I need to focus but I'm tired and distracted"
- A single `POST /mood/generate` call to the backend → Groq LLM maps to closest mood + generates playlist in one round trip
- Returns top 3 mood suggestions with confidence; user taps to confirm or adjust

**Voice Input (new)**
- Mic button beside the NL input bar
- Uses iOS `Speech` framework (on-device, free, no external API)
- Transcribed text feeds into the same NL → `POST /mood/generate` pipeline

**On-Device Fallback (during backend cold start)**
- Render free tier sleeps after 15 min inactivity; cold start takes ~2-3 seconds
- During this window, iOS falls back to Apple's `NaturalLanguage` framework for basic sentiment classification (positive / negative / neutral) and keyword matching against mood titles
- Result: The card picker pre-selects the most likely mood, user confirms, and playback begins while the backend warms up
- The fallback only handles mood classification — stream URLs for Jamendo are fetched once the backend responds; Apple Music playback works fully offline from the backend

### 3.2 Smart Source Routing (Backend Logic)

The backend auto-selects the best music source per mood. User never sees this decision but can override with one tap in Now Playing.

**Updated `PlaybackSource` model (replaces the existing `Provider` enum for playback):**

The existing `Provider` enum (`.appleMusic`, `.spotify`, `.youtubeMusic`) is kept for the **export/clone** destination. A separate `PlaybackSource` enum is introduced for **in-app playback**:

```swift
enum PlaybackSource: String, CaseIterable, Codable {
    case appleMusic   // MusicKit — requires subscription
    case youtube      // YouTubePlayerKit — free, mainstream catalog
    case jamendo      // AVPlayer — free, CC catalog, no ads
}
```

This decouples "where I send the playlist" from "what app I listen in."

**Routing table:**

| Mood Category | Primary Playback Source | Rationale |
|---------------|------------------------|-----------|
| `.focused`, `.chill`, `.relaxed` | **Jamendo** | Instrumental CC tracks; no lyrics, no ads — no distraction |
| `.energetic`, `.social`, `.magical` | **YouTube** | Mainstream catalog, latest hits |
| `.emotional`, `.romantic`, `.melancholy` | **YouTube** | Full catalog depth; music videos enhance emotion |
| Any mood (Apple Music subscriber) | **Apple Music** | Best quality, no ads, full catalog — always offered as upgrade |

**Jamendo → YouTube fallback:** If Jamendo returns < 5 tracks for a given mood, backend falls back to YouTube automatically.

### 3.3 Free In-App Playback

**YouTube playback**
- Powered by `YouTubePlayerKit` (already in project) using WKWebView embedding
- Ads are displayed as YouTube intends — not blocked or intercepted — complying with YouTube ToS section 4.B
- YouTube Data API v3: 10,000 units/day free. 1 search = 100 units → ~100 mood searches/day before quota
- Backend caches results by mood key — same mood query hits cache, not the API. Effectively extends quota to thousands of users per day
- Users with YouTube Premium see zero ads automatically

**Jamendo playback**
- Jamendo REST API (developer.jamendo.com) — 50,000 calls/month free
- Backend returns direct `.mp3` stream URLs per track
- iOS plays via native `AVPlayer` — zero latency, zero ads, Creative Commons licensed
- Catalog: 600,000+ tracks, strong in ambient, instrumental, lo-fi, electronic, jazz
- Catalog gap: No mainstream artists. Routing logic automatically uses YouTube for moods where mainstream catalog is expected (Energetic, Social)

**Apple Music playback (existing, unchanged)**
- `MusicKit` + `ApplicationMusicPlayer` — full in-app playback
- Requires user's Apple Music subscription
- Already fully implemented; kept as-is with no changes

### 3.4 Export / Clone Playlist (New — Headline Feature)

After any playlist is generated, a "Clone to your app" button is always visible in Now Playing. User picks destination:

**→ Spotify (backend-handled)**
- One-time OAuth login (Spotify Web API scopes: `playlist-modify-public`, `playlist-modify-private`)
- Backend creates playlist: `POST /v1/users/{id}/playlists`
- Backend searches Spotify catalog for each track by `"{title} {artist}"`, falls back to `"{title}"` only
- Result: Named playlist appears in user's Spotify app
- **See Risk #1 in Section 8 — Spotify Extended Quota Mode review required at > 25 users**

**→ Apple Music (iOS-only, no backend)**
- Handled entirely on-device via `MusicLibrary.shared.createPlaylist(...)`
- Matches tracks in Apple Music catalog using `MusicCatalogSearchRequest`
- User must have active Apple Music subscription to write to their library
- No backend involvement — MusicKit auth token stays on device

**→ YouTube Music (backend-handled)**
- One-time OAuth login (YouTube Data API v3 scopes: `youtube.force-ssl`)
- Backend creates playlist: `POST /youtube/v3/playlists`
- Backend adds videos: `POST /youtube/v3/playlistItems` per track
- Result: Playlist in user's YouTube Music library

**Track matching accuracy:** ~85% of tracks match by title + artist. Unmatched tracks are skipped. UI reports: "22 of 25 songs cloned ✓". This is expected and communicated clearly.

### 3.5 Backend Track Payload Schema

All playlists returned from `POST /mood/generate` use this JSON track shape:

```json
{
  "tracks": [
    {
      "id": "jamendo:track:123456",
      "title": "Morning Focus",
      "artist": "Blue Dot Sessions",
      "album": "Focus Works",
      "duration": 214,
      "stream_url": "https://mp3d.jamendo.com/...mp3",
      "artwork_url": "https://usercontent.jamendo.com/...jpg",
      "source": "jamendo",
      "energy": 0.3,
      "match_reason": "Instrumental, 68 BPM, tagged 'focus' by 1,200 listeners"
    }
  ],
  "mood": "Focused",
  "category": "focused",
  "energy": 0.35,
  "explanation": "Low tempo instrumentals — no lyrics to pull focus, minor key for concentration",
  "source": "jamendo"
}
```

The iOS `MusicTrack` model will be extended to include `streamURL: URL?` and `matchReason: String?` fields.

### 3.6 Persistence Model

**UserDefaults (existing — kept):** `recentMoods`, `favoriteMoods`, `userPreferences`, `statistics`

**SwiftData (new):** `savedPlaylists` and `exportedPlaylists` — these contain full track lists and are too large / too structured for UserDefaults. SwiftData (iOS 17+) is the appropriate choice: zero external dependency, iCloud sync available for free.

```swift
@Model class SavedPlaylist {
    var id: UUID
    var name: String
    var moodTitle: String
    var tracks: [MusicTrack]
    var source: PlaybackSource
    var createdAt: Date
    var exportedTo: [String]  // ["spotify", "apple_music"]
}
```

### 3.7 Navigation Redesign

| Tab | Icon | Content |
|-----|------|---------|
| **Vibes** | `music.note` | Mood picker + NL input + Now Playing mini-bar |
| **Library** | `books.vertical.fill` | Saved playlists, recent moods, exported playlists |
| **Stats** | `chart.bar.fill` | Mood streaks, listening time, mood patterns |
| **Profile** | `person.circle.fill` | Connected apps, settings, account |

### 3.8 Daily Engagement (Retention)

**Mood Streak**
- Track consecutive days user picks a mood
- Streak counter displayed on Stats tab
- Local notification: "Day 5 streak 🔥 — pick your mood today"

**Daily Push Notification**
- Smart timing: weekdays 8 AM, weekends 10 AM — using `UNUserNotificationCenter` (local, no server)
- Message varies by time: "Good morning — Focus music is ready" / "Wind down with tonight's Chill playlist"

**Challenges Tab → Real Content (replaces current placeholder)**
- Weekly listening goal: e.g., "Listen across 3 different mood categories this week"
- Badge system: First Playlist, 7-Day Streak, Export Master, Mood Explorer
- Existing `ChallengeCard` component kept; backed by real progress data

### 3.9 Now Playing Screen (Redesigned)

- Full-screen mood artwork with cinematic blurred ambient background
- Track title + artist
- Standard playback controls (play/pause, skip, previous)
- **"Clone to app" CTA button** — always visible
- **"Why this song?"** expandable → shows `match_reason` from backend
- Source badge (`Jamendo` / `YouTube` / `Apple Music`) — tap to override source
- Mini-bar version floats above tab bar when music is active

---

## 4. Python Backend

### 4.1 Stack

```
FastAPI (Python 3.11)
├── Groq Python client (mood NL classification)
├── httpx (async HTTP for Last.fm, Jamendo, YouTube APIs)
├── cachetools or dict cache (in-memory, API quota protection)
└── Uvicorn (ASGI server)
```

No database required for MVP. Cache is in-memory (resets on cold start — acceptable).

### 4.2 Endpoints

**Single round-trip design — mood classification and playlist generation are combined:**

```
POST /mood/generate
  body:  { "input": "I need to focus but I'm tired", "source_override": null }
  returns: {
    mood, category, energy, explanation,
    top_moods: [{ mood, confidence }],
    tracks: [TrackObject],
    source: "jamendo" | "youtube"
  }

POST /playlist/export
  body:  { "tracks": [TrackObject], "destination": "spotify" | "youtube", "auth_token": "..." }
  returns: { "playlist_id": "...", "matched_count": 22, "total_count": 25 }
  note:  Apple Music export is NOT handled here — iOS-only via MusicKit

GET /health
  returns: { "status": "ok" }
```

### 4.3 Deployment

- **Platform:** Render.com free tier
- **Specs:** 512MB RAM, shared CPU — sufficient for < 5,000 DAU
- **Cost:** $0/month
- **Cold start:** ~2-3 seconds after 15 min inactivity. iOS handles this gracefully via on-device NL fallback (see Section 3.1)
- **Scale path:** Render Starter ($7/month) at 5K+ DAU

### 4.4 API Keys Required (All Free Tiers)

| Service | Key Type | Cost | Signup |
|---------|----------|------|--------|
| Groq | API key | Free (30 req/min) | console.groq.com |
| Last.fm | API key | Free (unlimited) | last.fm/api/account/create |
| Jamendo | Client ID | Free (50K req/month) | developer.jamendo.com |
| YouTube Data v3 | API key | Free (10K units/day) | console.cloud.google.com |
| Spotify Web API | Client ID + Secret | Free | developer.spotify.com |

---

## 5. Visual Design

### 5.1 Design Language (Magnetto-Inspired)

- **Background:** `#0A0A0F` (near-black, slightly warm)
- **Cards:** Full-bleed mood artwork, cinematic lighting, `28pt` rounded corners
- **Typography:** SF Pro Display Bold (headings), SF Pro Text (body)
- **Accent colors:** Mood-reactive — each mood pulses its color palette into the UI (already built in `EnhancedMoods.swift`)
- **Motion:** Spring animations on mood selection, parallax on cards

### 5.2 Key Screen Descriptions

**Vibes Tab (Home)**
- NL input bar at top: "How are you feeling?" with mic button
- Category filter pills below (horizontal scroll, 8 categories)
- Mood card grid: large, full-bleed, editorial
- Floating Now Playing mini-bar when music is active

**Now Playing (Full Screen)**
- Cinematic blurred artwork background
- Track info centered
- Playback controls
- "Clone to app" CTA (prominent)
- "Why this song?" expandable explanation

**Library Tab**
- Saved playlists (SwiftData, card grid)
- Exported playlists with destination app badge (Spotify green / Apple pink / YT red)
- Recent moods (horizontal chips, UserDefaults)

**Stats Tab**
- Mood streak counter (large, prominent)
- Mood frequency (which moods used most)
- Listening time this week
- Most used source

---

## 6. What Is Not In Scope (V1)

- SoundCloud integration (API registration closed for new apps since 2022)
- Core ML fine-tuned mood model (Approach 3 — save for v2 once usage patterns are known)
- Social/sharing features (mood sharing cards)
- Android or web app
- Paid subscription tier
- Offline playback (Jamendo + YouTube require internet)
- Server-side mood analytics (opted-in only; out of scope for v1)

---

## 7. Success Metrics

| Metric | Month 1 Target | Month 3 Target |
|--------|---------------|---------------|
| Downloads | 200+ | 1,000+ |
| Day-7 retention | > 20% | > 30% |
| Export feature usage | > 10% of DAU | > 20% of DAU |
| NL input usage | > 20% of mood selections | > 40% |
| Crash-free rate | > 99% | > 99% |

---

## 8. Risks & Open Questions

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | **Spotify Extended Quota Mode:** Apps serving > 25 users must apply for Extended Quota Mode to use `playlist-modify-*` scopes. Review takes 2-6 weeks and can be rejected. | High | Apply during development before launch. Use a fallback: if quota not approved, show "Coming soon for Spotify" and prioritize Apple Music + YouTube Music export. |
| 2 | **YouTube ToS / App Store Review:** YouTubePlayerKit uses WKWebView embedding. YouTube ToS section 4.B prohibits ad blocking or bypass. App Store reviewers have rejected apps for YouTube embedding in the past. | High | Show YouTube ads as rendered natively by the WKWebView — do not intercept or suppress them. Include in App Store review notes that embedding is via official WKWebView iframe, compliant with YouTube's iframe embed policy. |
| 3 | **YouTube API Quota:** 10K units/day = ~100 unique mood searches without caching. | Medium | Backend caches all YouTube results by mood key (1-hour TTL). Same mood query returns cached results, not a fresh API call. |
| 4 | **Render Cold Start:** 2-3s delay after inactivity. | Low | On-device NL fallback (Section 3.1) handles mood classification. Loading state + skeleton UI on first backend call. |
| 5 | **Jamendo Catalog Gaps:** No mainstream artists. Some popular mood categories will have unfamiliar tracks. | Low | Routing logic auto-switches to YouTube for moods where mainstream catalog matters (Energetic, Social, Romantic). |
| 6 | **Apple Music Playlist Write:** Requires active Apple Music subscription. | Low | Clearly communicated in UI. Spotify/YouTube Music export always available as alternative. |
| 7 | **Emoji Duplication in Existing Moods:** Two moods share `⚡` (Excited, Electric) and two share `🎭` (Melancholy, Dramatic) in `EnhancedMoods.swift`. May cause display or NL matching confusion. | Low | Assign unique emoji to each mood during card redesign phase. |
| 8 | **`allMoods` vs `enhancedMoods` naming inconsistency:** `MusicController.swift` references `allMoods` which does not exist — `EnhancedMoods.swift` defines `enhancedMoods`. | Medium | Fix during `MusicController` refactor in implementation. Replace all `allMoods` references with `enhancedMoods`. |
| 9 | **`MusicAuthorization.request()` catch block never executes:** The `do/catch` in `MusicController.refreshAuthorizationStatus()` wraps a non-throwing function. | Low | Fix during implementation: remove the `do/catch` wrapper; handle authorization state directly. |
