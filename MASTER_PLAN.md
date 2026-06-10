# MeloMo — Ultimate Master Plan
# Version 2.0 | June 2026 | For Internal Review Only
# Reviewed by: Claude Opus 4.6 safety agent — all critical issues resolved

---

## Executive Summary

MeloMo is repositioned from a mood-picker music app into an **Emotional Navigation System** — the
only consumer product that uses real biometric signals, the research-supported ISO therapeutic
music principle, and a living reactive UI to move users from how they feel to how they want to feel,
using real songs. No competitor does this. The plan covers full product architecture, a
near-zero marginal-cost backend that scales to ~100k daily active users before significant spend,
and a monetization stack designed to reach $10k MRR net with approximately 2,870 premium subscribers.

**Critical pre-build actions before Phase 0 starts**:
1. Contact licensing@jamendo.com — get commercial API license quote. Budget unknown. Do not build offline kits without this.
2. Decide YouTube strategy: show visible player or drop YouTube entirely (1×1 hidden player violates ToS).
3. Add payment method to Groq account (unlocks 10× rate limits for spike protection).

---

## Part 1: Product Strategy

### 1.1 The Core Differentiator

Every competitor picks one of two things:
- **Music that matches your mood** (Spotify mood playlists, Apple Music radio) — reactive, no intelligence
- **Ambient audio that adjusts to your body** (Endel, Brain.fm) — biometric, but not real music

MeloMo does what neither does: **real songs + biometric awareness + music that transitions your
emotional state from A to B**, using the ISO therapeutic music principle (supported by peer-reviewed
research: MDPI 2021, SAGE 2024 — evidence-informed, not a medical claim) where playlists start
where you are and gradually move you toward where you want to be.

The positioning sentence: *"Music that moves you — not just matches you."*

### 1.2 Target Users (Both, Not Either/Or)

- **Wellness-oriented** (25-40): use the app during commutes, work sessions, pre-sleep, gym
  wind-down. Value: biometric intelligence, transformation playlists, offline kits.
- **Music explorers** (18-35): want better discovery than Spotify's algorithm, care about
  independent artists, want music that fits their actual state. Value: Resonance Wheel,
  Jamendo discovery, "Why this song" explanations.

These audiences overlap heavily in the 22-35 bracket.

### 1.3 Competitive Moat

| Feature                        | Spotify | Endel | Brain.fm | MeloMo |
|-------------------------------|---------|-------|----------|--------|
| Real songs (not just ambient) | ✓       | ✗     | ✗        | ✓      |
| Biometric detection           | ✗       | ✓     | ✗        | ✓      |
| ISO emotional arc playlists   | ✗       | ✗     | ✗        | ✓      |
| Offline curated emotional kits| ✗       | ✗     | ✗        | ✓      |
| BPM haptic entrainment        | ✗       | ✗     | ✗        | ✓      |
| Dynamic valence-driven visuals| ✗       | partial| ✗       | ✓      |
| Apple Music + Jamendo + YouTube| ✗      | ✗     | ✗        | ✓      |

---

## Part 2: The Resonance Engine — Design System

### 2.1 Validated Design Concepts (Build These)

**A. BPM Haptics Engine**
CoreHaptics `CHHapticEngine` with custom waveform patterns per track. Jamendo returns BPM in
`musicinfo`. Apple Music exposes `Song.tempo`. YouTube tracks get BPM estimated from energy/genre.
Parameters: `CHHapticEventParameter.hapticSharpness` maps to genre energy (0.0 = silk for ambient,
1.0 = sharp for rock). Repeating `CHHapticPattern` at BPM interval. Capped at 140 BPM for
comfort; above that, fire on every 2nd beat. Stops on pause.

**B. Dynamic Ambience — MeshGradient Background**
iOS 18+ `MeshGradient` with 9 control points. Control points animate toward colors mapped to the
current track's valence-arousal coordinates. Transition: 10-second cross-fade so it's felt, not
watched. Stressed track → desaturated orange-red. Calm track → deep teal-blue. Excited → warm gold.
Fallback for devices running iOS 17 or earlier: animated `LinearGradient` with the same color palette.

**C. Breathing Typography**
Track title + artist animate at BPM/4 (quarter-note breath cycle). `.scaleEffect(1.0 → 1.015)` +
`.opacity(1.0 → 0.92)`. Imperceptible consciously, felt subconsciously. Entrainment hook.

**D. Living Vinyl — Z-Axis Elevation**
`AVAudioEngine.installTap()` on Jamendo/AVPlayer source for real RMS levels. YouTube source:
BPM-driven sine wave approximation (cannot tap WKWebView audio). Vinyl responds: louder = larger
scale + deeper shadow + `rotation3DEffect` tilting 5-8° forward. 12-Circle groove rendering
replaced with single `Canvas` draw call (performance fix + animated flex on loud passages).

**E. Rough vs. Smooth Haptics by Genre**
Same `CHHapticEngine`, different `sharpness` parameter per energy tier. Already exposed in the API.
Rock/hype = 0.8 sharpness. Ambient/chill = 0.1. 2 hours of implementation, genuinely delightful.

**F. Reminiscence Algorithm**
Onboarding: "What decade shaped your music taste?" (70s/80s/90s/00s/10s/20s). Stored locally.
Sent as `era_preference` in generate requests. Backend seed map weights toward that era's sonic
fingerprint. Not a separate algorithm — a backend seed modification.

**G. Two Intent Modes**
- Focus Mode: UI collapses to vinyl orb + track name + two controls. Triggered when destination
  emotion is focused/calm. `transition(.opacity.combined(with: .scale))`.
- Discovery Mode: Full vinyl + arc visualization + artist context + "Why this song" card.
  Default rich mode.

### 2.2 Concepts That Don't Survive Contact With Reality (Skip)

**True refractive glass**: SwiftUI `Material` + `ultraThinMaterial` looks identical to true
refraction at 60fps and costs zero Metal shader development time. Use this instead.

**Ripples displacing sibling views**: Build the ripple via `Canvas + TimelineView`. Skip the
physics-based displacement of other views — it becomes a maintenance nightmare as layout evolves.

**Real-time frequency spectrum for YouTube**: Cannot tap `WKWebView` audio stream.
Use BPM-driven animated wave math. Visually indistinguishable from real FFT at normal playback.

**VHS/CRT visual filters as default UI**: Niche taste, not universal appeal. Opt-in Easter egg
only, not default visual language.

---

## Part 3: The Emotion Engine

### 3.1 Valence-Arousal Model

Replace "mood labels" with a 2D emotional coordinate system:

```
Valence:  -1.0 (negative) → +1.0 (positive)
Arousal:  -1.0 (low energy) → +1.0 (high energy)

Stressed:    valence -0.5, arousal +0.8
Calm:        valence +0.5, arousal -0.7
Excited:     valence +0.8, arousal +0.8
Sad:         valence -0.8, arousal -0.5
Focused:     valence +0.3, arousal +0.1
Anxious:     valence -0.6, arousal +0.6
```

Every track gets estimated coordinates. Jamendo: BPM + mood tags → estimated arousal and valence.
Apple Music: `Song.tempo` + `Song.genre` → estimated. YouTube: title + channel signals via Groq.

### 3.2 The Resonance Wheel (Primary Input UI)

A circular 2-axis dial rendered in `Canvas`. User drags a point (their current state).
A second point (destination). Path between them = emotional arc. Background color shifts
to match selected quadrant in real-time. This replaces the mood grid entirely.

### 3.3 ISO Arc Playlist Algorithm

```
Input: (currentValence, currentArousal, targetValence, targetArousal, n_tracks=12)

1. Calculate straight-line path in valence-arousal space
2. Divide path into n_tracks segments
3. For each segment, find tracks with coordinates within ±0.15 of segment midpoint
4. Order tracks as smooth progression along the arc
5. Return ordered playlist with per-track arc_position metadata
```

iOS NowPlayingView receives arc metadata and shows progress marker:
"You are here → moving here" with animated position dot.

### 3.4 Updated Groq Prompt

```
You are an emotion-music classifier. Given user input and optional biometrics, return JSON:
{
  "valence": float -1.0 to 1.0,
  "arousal": float -1.0 to 1.0,
  "emotion_label": string,
  "explanation": string (one sentence, references biometrics if provided),
  "target_suggestion": { "valence": float, "arousal": float, "label": string } | null,
  "top_moods": [{ "mood": string, "valence": float, "arousal": float, "confidence": float }]
}
Return ONLY valid JSON. No markdown. No extra text.
```

---

## Part 4: Biometric Intelligence

### 4.1 HealthKit Signals

Requires HealthKit authorization. All data stays on-device — never sent to backend raw.
Only the inferred emotional coordinates are sent. All HealthKit signals below are available
on iOS 18+ (not watchOS-exclusive).

| Signal                        | HealthKit Type                          | Inference Use               |
|------------------------------|-----------------------------------------|-----------------------------|
| Current heart rate           | HKQuantityType.heartRate                | Arousal proxy               |
| HRV (SDNN)                   | HKQuantityType.heartRateVariabilitySDNN | Stress marker               |
| 7-day HRV baseline           | HKStatisticsQuery                       | Personal baseline for delta |
| Last night's sleep quality   | HKCategoryType.sleepAnalysis            | Fatigue modifier            |
| Recent activity (30 min)     | HKQuantityType.stepCount                | Activity state              |
| State of Mind log            | HKStateOfMindSample (iOS 18+ / watchOS 11+) | Self-report anchor     |

### 4.2 Confidence Scoring

Never claim certainty. Always show reasoning.

```swift
struct BiometricSnapshot {
    let arousalEstimate: Float       // -1.0 to 1.0
    let stressSignal: Float          // 0.0 to 1.0
    let confidence: Float            // 0.0 to 1.0
    let reasoning: String            // Human-readable explanation

    // Example reasoning:
    // "Your HR is 18% above your resting average. HRV is 25% below your weekly
    //  baseline. Combined with last night's 5.5hr sleep, this suggests elevated
    //  stress or fatigue. Confidence: 71%."
}
```

Accuracy ceiling from research: ~85% for 2-state (calm vs stressed) classification.
Never attempt to infer 5+ discrete emotions from biometrics alone — accuracy drops to ~52%
(estimated from multi-class HRV classification literature; treat as indicative, not authoritative).
Always allow user to confirm or correct the reading (one tap on the Resonance Wheel).

### 4.3 Background Delivery

`HKObserverQuery` for background heart rate updates when app is backgrounded.
Passive emotional state updates without requiring the app to be open.
Enables proactive pre-loading of appropriate playlists.

---

## Part 5: Offline Emotional Kits

### 5.0 CRITICAL: Jamendo Commercial License Required

**Before building any offline kit feature**: Jamendo's API Terms of Use prohibit commercial use
without a separate license. A $4.99/month subscription app is unambiguously commercial.
Downloading tracks for offline redistribution in a paid app requires a Jamendo commercial
partner agreement.

**Action required**: Email licensing@jamendo.com before Phase 4 begins.
Ask for: commercial API license quote, offline caching rights, and tip payout partner terms.
Budget line item: TBD (could range from hundreds to thousands per month — get the quote).
If the cost is prohibitive: replace offline kits with Apple Music downloaded playlists
(user's own subscription, zero licensing cost to MeloMo) for Premium users.

### 5.1 Kit Structure

```swift
@Model
final class OfflineKit {
    let id: String
    let name: String              // "Pressure Release"
    let tagline: String           // "From stressed to calm in 40 minutes"
    let arcStart: EmotionCoord    // where the kit starts
    let arcEnd: EmotionCoord      // where it takes you
    var tracks: [MusicTrack]      // 40-60 Jamendo tracks, arc-ordered
    var downloadState: DownloadState
    let totalDuration: TimeInterval
    let estimatedSizeBytes: Int
    let tier: KitTier             // .free (1 starter kit) or .premium
}
```

### 5.2 The 6 Launch Kits

| Kit Name           | Arc                        | Duration | Tier    | Use Case              |
|--------------------|----------------------------|----------|---------|-----------------------|
| Starter Pack       | Any → Calm                 | 25 min   | Free    | Introduction kit      |
| Pressure Release   | Stressed → Calm            | 40 min   | Premium | Work stress, commute  |
| Morning Momentum   | Tired → Energized          | 35 min   | Premium | Pre-coffee Monday     |
| Deep Focus         | Scattered → Concentrated   | 60 min   | Premium | Study, deep work      |
| Comfort Mode       | Sad → Accepted             | 45 min   | Premium | Hard days             |
| Wind Down          | Active → Sleepy            | 30 min   | Premium | Pre-sleep             |

### 5.3 Smart Pre-loading

Pattern detection stored in `AppStatistics` as a usage heatmap (hour × weekday grid).
If 5+ sessions fall in the same hour across 3+ weekdays → trigger pre-download of the
most-used kit for that time window on the preceding evening.

Background download via `URLSession.backgroundConfiguration`. User sees progress in
Settings: "3 kits downloaded · 480 MB used."

---

## Part 6: Backend Architecture — Near-Zero Marginal Cost

### 6.1 Migration from Render to Cloudflare Workers

**Problem with current setup**: Render free tier has 10-15 second cold starts after 15 minutes
of inactivity. This kills the magic moment.

**Solution**: Cloudflare Workers free tier.
- 100,000 requests/day free, never expires, commercial use allowed
- Sub-millisecond cold start (Workers use V8 isolates, not containers — always warm)
- Secrets stored in environment: GROQ_API_KEY, YOUTUBE_API_KEY, JAMENDO_CLIENT_ID
- KV storage free tier: 100k reads/day for trending vibes
- $5/month paid plan unlocks 10M requests/day if needed

**Migration**: Rewrite ~200 lines of FastAPI Python in TypeScript (Hono framework).
Estimated migration time: 2-3 days. FastAPI patterns map directly to Hono routes.

### 6.2 On-Device Offload (Reduces Groq Calls ~75%)

Current: Every session calls Groq. At 14,400 req/day free tier limit, this caps at ~600 DAU.

New: Three-tier classification:

```
Tier 1 — On-device CoreML (free, instant, ~75% of requests):
  Standard mood labels ("Focus", "Happy", "Chill", "Energetic")
  NaturalLanguage framework + CreateML classification model
  Trained on: mood title → valence/arousal coordinate mapping
  No network call. No cost.

Tier 2 — Groq Llama 3.1 8B (free tier, handles ~25% of requests):
  Freeform natural language ("I feel like the world is ending")
  Biometric context classification (Magic Mood)
  Complex blended emotions
  ~150 input + 200 output tokens = 350 tokens/call

Tier 3 — Groq Llama 3.3 70B (paid, reserved for biometric+NL combo):
  When biometrics + complex language input combined
  Highest quality classification
  ~$0.59/M input, $0.79/M output — negligible at current scale
```

**Groq rate limits that actually throttle before daily cap**:
- Free tier: 14,400 req/day AND **30 requests/minute** AND **6,000 tokens/minute**
- Llama 3.1 8B free tier: 500,000 tokens/day budget
- At even 10 concurrent users, the 30 RPM cap hits in burst scenarios
- Mitigation: add Groq payment method → unlocks ~300 RPM + 30k TPM on pay-as-you-go

### 6.3 YouTube Compliance — Architecture Decision Required

**YouTube Terms of Service explicitly prohibit**:
1. Background audio playback (player window closed/minimized)
2. Obscuring the player or any portion of its controls
3. Extracting audio from the embedded player

The current 1×1 hidden player architecture violates all three. Risk: YouTube API key revocation
and App Store rejection. YouTubePlayerKit's own documentation flags background audio as a ToS violation.

**Two viable paths — choose one before Phase 0**:

| Option | Implementation | UX Impact | Risk |
|--------|---------------|-----------|------|
| A: Visible player | Show YouTube player at minimum 200×113px in NowPlayingView for YouTube tracks | Different layout for YouTube vs. Jamendo tracks | Low — fully compliant |
| B: Drop YouTube | Remove YouTube source entirely, strengthen Jamendo + Apple Music | No YouTube content; slightly fewer tracks in some genres | None — eliminates the risk entirely |

**Recommendation**: Drop YouTube. The added complexity of maintaining a visibly different
NowPlayingView layout for YouTube tracks creates a second-class experience. Jamendo has 600k+
tracks; Apple Music covers everything else for premium users. YouTube can be re-evaluated
after the core product is stable.

### 6.4 Cost Projections at Scale

**Groq cost calculation** (Llama 3.1 8B at $0.05/M input, $0.08/M output):

| DAU    | Groq Calls/day | Tokens/day | Cost/day | Cost/month |
|--------|---------------|------------|----------|------------|
| 1,000  | 250           | 87,500     | $0.008   | $0.25      |
| 10,000 | 2,500         | 875,000    | $0.084   | $2.52      |
| 50,000 | 12,500        | 4,375,000  | $0.42    | $12.60     |
| 100,000| 25,000        | 8,750,000  | $0.84    | $25.20     |

**Full infrastructure cost at 100k DAU**:

| Service                | Free Tier Limit         | At 100k DAU      | Cost/month      |
|-----------------------|-------------------------|------------------|-----------------|
| Cloudflare Workers    | 100k req/day            | Paid plan needed | $5.00           |
| Groq API              | 14,400 req/day + 30 RPM | Paid tier        | $25.20          |
| YouTube API           | N/A if dropped (Option B)| N/A             | $0.00           |
| Jamendo API (streaming)| 50k calls/month        | Heavy caching    | $0.00 streaming |
| Jamendo commercial license | TBD (get quote)   | Fixed cost       | TBD             |
| RevenueCat            | Free <$2,500 MTR        | 1% of MTR        | ~$40.00         |
| **Total (ex-Jamendo)**|                         |                  | **$70.20**      |

*Jamendo commercial license cost is unknown until negotiated. Budget for it before projecting
"zero cost" infrastructure. If license fee is $200/month, break-even rises from 21 to ~61 subs.*

**Break-even point (without Jamendo license)**: 21 premium subscribers at $4.99/month net covers
100k DAU infrastructure. With Jamendo license: recalculate after getting quote.

### 6.5 Free Tier Duration by Scale

| Stage                | DAU      | Infrastructure cost | Notes                              |
|---------------------|----------|---------------------|------------------------------------|
| Launch → 1k DAU     | 0-1,000  | ~$0/month           | All free tier limits               |
| Growth → 10k DAU    | 1-10k    | ~$0/month           | Groq stays under free limit        |
| Scale → 100k DAU    | 10-100k  | ~$70+/month         | Groq paid, CF Workers paid         |
| At $10k MRR         | ~40k DAU | ~$40+/month         | Revenue covers costs comfortably   |

---

## Part 7: Monetization Plan

### 7.1 Primary Revenue — Subscriptions (Target: 80% of revenue)

**Pricing (based on RevenueCat 2025 data: 47.8% trial-to-paid at $4.99 tier)**:

- Monthly: **$4.99/month** with **7-day free trial**
- Annual: **$34.99/year** (~$2.92/month, 42% saving) with **14-day free trial**
  (Headspace data shows 14-day trial lifts annual conversion significantly)

Annual plan highlighted as default in paywall UI (saves $24.89 vs monthly equivalent).

**Apple's cut**:
- Year 1: 30% → $3.49 net per monthly sub, $24.49 net per annual sub
- Year 2+ (Small Business Program, <$1M proceeds): 15% → $4.24 net monthly, $29.74 net annual
  Note: enrollment requires an application to Apple; not automatic. Rate begins 15 days after
  the end of the fiscal month of approval.

**Revenue projections (blended 60% monthly / 40% annual)**:

| Premium Subs | Blended gross/month | After Apple 30% | Infrastructure | Net Profit/month |
|-------------|---------------------|-----------------|----------------|------------------|
| 500         | ~$2,495             | ~$1,747         | $0             | $1,747           |
| 1,000       | ~$4,990             | ~$3,493         | $0             | $3,493           |
| 2,870       | ~$14,321            | ~$10,025        | $40            | ~$9,985          |
| 5,000       | ~$24,950            | ~$17,465        | $70            | ~$17,395         |
| 10,000      | ~$49,900            | ~$34,930        | $130           | ~$34,800         |

Path to $10k MRR net: **2,870 premium subscribers** (all-monthly assumption; with annual mix,
actual subscriber count needed is slightly different — annual subs front-load cash).

**Conversion rate planning (do not use 8% as base case)**:
- Industry range for subscription wellness apps: 2-8%
- 3%: conservative base case → needs **95,667** active free users
- 5%: realistic upside → needs **57,400** active free users
- 8%: top-quartile — only plan to this if ASO + influencer channel is performing

**Annual subscriber retention advantage (RevenueCat 2025 data)**:
Annual: 44.1% retention after 12 months. Monthly: 17.5%. LTV of annual subscriber ≈ 3.8x monthly.
Aggressively promote annual plan — it's better for both MRR stability and the user (cheaper).

### 7.2 Tier Definitions

**Free (permanently free — this is the acquisition engine)**:
- 10 emotion sessions per day
- Resonance Wheel emotion picker
- BPM haptics (all users — this is a magic moment driver, never a gate)
- Jamendo source (and YouTube if kept)
- Basic arc (5 tracks, simplified ISO sequence)
- 1 offline kit (Starter Pack — 20 tracks, 25 min)
- 7-day emotional history
- Streak tracking + journal

**Premium ($4.99/month or $34.99/year)**:
- Unlimited sessions
- Apple Music source (user's own subscription required — communicated in onboarding)
- Full Biometric Snapshot (HRV + sleep + activity combined)
- Full ISO arc (12-track deep sequence)
- All 6 offline kits + new kits as they ship
- 90-day emotional history + pattern insights
- Reminiscence era personalization
- Focus Mode + Discovery Mode
- "Why this song" explanation card for every track
- Priority classification (Llama 3.3 70B instead of 8B for biometric sessions)

**What to NEVER gate**:
- BPM haptics — it's the magic moment that drives word-of-mouth
- The Resonance Wheel UI itself — it's the identity, free users must experience it
- Streak tracking — gamification drives daily opens which drives conversion

### 7.3 Paywall Trigger Strategy

**Do NOT** interrupt with a modal on 3rd launch (industry data: aggressive paywalls reduce
30-day retention by 32%). Instead:

- After 3rd session: non-intrusive banner at bottom: "Unlock the full arc + offline kits"
- After first "offline kit" tap by free user: sheet explaining "Download kits with Premium"
- After biometric snapshot: "Your full biometric history unlocks with Premium — see your patterns"
- Never block the core loop. Always let the user complete a session before showing any upsell.

### 7.4 Secondary Revenue — B2B Corporate Wellness (Target: 15% of revenue, 6-12 months out)

**Market**: Mental health/wellness B2B market reached $7.5B in 2025. Corporate wellness apps
charge $1-$6/user/month. Employer adoption is accelerating.

**Regulatory requirement before building B2B**:
- Do NOT offer emotional state detection as a health or diagnostic service. MeloMo is
  entertainment software, not a medical device. Any copy suggesting stress measurement,
  clinical accuracy, or health improvement triggers FDA wellness device review.
- Aggregate emotional trend reports for employers raise GDPR Article 9 concerns (biometric-
  derived data is sensitive data requiring explicit consent for each specific use, including
  employer reporting). In the EU, employer emotional surveillance is legally and politically
  high-risk.
- Minimum required before B2B launch: a legal opinion on medical device classification,
  a privacy lawyer review of the B2B dashboard, and explicit per-user opt-in for
  employer-visible trend data.

**MeloMo B2B product** (build after consumer product is stable AND legal review done):
- Organization dashboard: aggregate music usage patterns (not emotional diagnoses)
- Bulk licensing: $49/month up to 50 users (~$0.98/user, competitive)
- Custom branding option: "Powered by MeloMo" with company colors
- Therapist/coach tier: $29/month for individual practitioners to recommend to clients
  (frame as "music recommendation tool" not "emotional therapy")

**Target channels**:
1. Mental health apps (Woebot, Wysa) as an audio partner integration
2. Corporate HR platforms (Lattice, Culture Amp) as a wellness widget
3. Direct LinkedIn outreach to HR Directors at companies 50-500 employees
4. Therapist networks (Psychology Today directory outreach)

**Revenue potential**: 10 companies × $49/month = $490/month initially.
Scale: 100 companies = $4,900/month as a standalone revenue stream.

### 7.5 Tertiary Revenue — Artist Tips (Target: 5% of revenue)

Jamendo artists are credited in NowPlayingView. Add a "Support this artist" button.
User tips any amount. MeloMo takes a platform fee; remainder goes to artist.

**Corrected economics** (after Apple's 30% cut on all IAP):
- On a $4.99 tip: Apple takes $1.50. MeloMo keeps 10% of remainder = $0.35. Artist gets $3.14.
- User pays $4.99 → artist receives $3.14 (63%). Present this honestly in the UI.
- Do not advertise "90% goes to artist" — the actual artist cut after Apple's cut is 63%.

**Why this matters beyond revenue**:
- Press story: "The app that pays independent musicians"
- Differentiates MeloMo from Spotify's notoriously low artist payouts
- Builds loyalty with Jamendo artists who promote the app organically

**Implementation**: Simple IAP one-time purchase tiers ($1.99, $4.99, $9.99 "tip" products).
Disbursement: requires Jamendo commercial partner agreement (confirm payout API exists before
building — Jamendo may or may not support third-party tip forwarding).

### 7.6 Growth — Micro-Influencer Partnership Strategy

**Data from research**: Micro-influencers (10k-100k followers) generate 60% higher conversion
rates than macro-influencers. Note: ROI figures for subscription apps should be measured by
LTV (12+ month value), not immediate conversion value — the $5-6.50/$1 e-commerce benchmark
does not directly apply.

**Target niches** (not generic music influencers):
1. Productivity/study TikTok/YouTube (LoFi channels, "study with me" content)
2. Wellness/mental health Instagram (anxiety, burnout recovery, therapy content)
3. Journaling/self-improvement communities
4. Remote work lifestyle content

**Offer structure**:
- Free premium subscription for life
- 30% affiliate commission on Premium conversions
- Tracking: RevenueCat offer codes identify which influencer drove a conversion, but RevenueCat
  does NOT disburse affiliate commissions. Commissions must be tracked and paid manually, or
  via a dedicated affiliate platform (e.g., Rewardful, PartnerStack, or custom logic).
- Performance-based only. If they drive 10 conversions/month, they earn $10.47/month
  (30% of $3.49 net per sub). Simple, scalable.

**Apple Performance Partners note**: This program pays commissions on Apple Music memberships
and media purchases. It does NOT pay commissions on third-party app subscriptions — you cannot
earn affiliate revenue on your own app's IAP through this program. Remove from affiliate strategy.

### 7.7 Subscription Infrastructure — RevenueCat

**Why RevenueCat over raw StoreKit 2** (research-backed decision):
- Free until $2,500/month MTR (Monthly Tracked Revenue — includes tips + subscriptions)
- 30-minute integration vs weeks of custom StoreKit 2 implementation
- Built-in paywall A/B testing (apps running 50+ paywall experiments grow revenue 100x)
- Revenue analytics, churn prediction, cohort analysis out of the box
- Both use StoreKit 2 under the hood — migration to pure StoreKit 2 later if needed, no lock-in

**RevenueCat cost at scale** (based on MTR, not just subscription MRR):
- Free: $0-$2,500 MTR
- Grow: 1% of MTR from $2,500 → ~$100 at $10k MTR
- Scale: Custom pricing above $10k MTR (negotiable)

**StoreKit 2 subscription states to handle** (not binary — 6 states):
1. Subscribed — full access
2. In Grace Period — payment failed, Apple gives 6-16 days to fix billing → **still grant access**
   (cutting access during grace period causes subscription loss)
3. In Introductory Offer — free trial active
4. Expired — access revoked
5. Billing Retry — Apple is retrying payment automatically
6. Revoked — refund processed

RevenueCat handles all 6 states with a single `CustomerInfo` object.

---

## Part 8: Analytics Infrastructure

Analytics is not optional — without it, all conversion optimization in Phases 5-6 is guesswork.
Must be in place before monetization launches.

### 8.1 What to Track

**Funnel events**:
- `app_open`, `onboarding_complete`, `first_session_complete`
- `resonance_wheel_used`, `biometric_snapshot_requested`
- `paywall_shown`, `paywall_dismissed`, `trial_started`, `subscription_purchased`
- `offline_kit_tapped` (free user), `offline_kit_downloaded` (premium)
- `artist_tip_initiated`, `artist_tip_completed`

**Retention events**:
- Daily active usage (streak-driven)
- Session depth (tracks played per session)
- `arc_completed` (user plays through full ISO sequence)

### 8.2 Tool Recommendation

**PostHog** (open-source, self-hosted option available, GDPR-compliant):
- Free up to 1M events/month on cloud tier
- Session recording, funnel analysis, A/B testing built-in
- No user PII required — use anonymous session IDs
- Does not conflict with Apple's ATT framework (no cross-app tracking)

Alternative: Firebase Analytics (Google's ecosystem, free, but sends data to Google servers —
review GDPR implications if EU users are a target audience).

### 8.3 Privacy Constraints

- No analytics on HealthKit data, biometric readings, or inferred emotion coordinates
- Anonymous session IDs only — no name, email, or Apple ID linked to events
- EU users: analytics consent banner required under GDPR if using cloud-hosted PostHog or Firebase
- Declare analytics data usage in App Store Privacy Nutrition Label

---

## Part 9: Legal & Privacy Compliance

This section is non-negotiable before shipping any HealthKit feature.

### 9.1 GDPR Requirements (EU Users)

**Data Protection Impact Assessment (DPIA)**:
GDPR Article 35 requires a DPIA before processing health or biometric data at scale.
This applies to MeloMo because biometric signals (HRV, heart rate, sleep) are processed to
infer emotional states. The DPIA documents: what data is processed, why, for how long,
what the risks are, and what mitigations exist.
- The fact that data stays on-device reduces the risk level significantly
- The inferred emotion coordinates (valence/arousal floats) sent to the backend may
  qualify as derived health data under some EU interpretations — document this explicitly
- Retention: emotional history auto-deletes after 90 days (premium) or 7 days (free)

**Required before EU launch**: Complete a DPIA. Template available at ICO (UK) or your
local DPA. Budget 4-8 hours for a solo developer with the template.

### 9.2 US State Privacy Laws

**California (CCPA/CPRA)**:
- Biometric data and inferred emotional states qualify as "sensitive personal information"
- Requires: right to opt out of sharing, right to limit use, right to delete
- "Do Not Sell or Share My Personal Information" link in Settings
- MeloMo does not sell data — but must still provide the opt-out mechanism

**Illinois (BIPA — Biometric Information Privacy Act)**:
- Requires written consent before collecting biometric information
- Applies to heart rate and HRV data if used to generate user-identifying profiles
- HealthKit authorization acts as consent — but must be explicit in the authorization prompt
- Mitigation: add a consent screen before the first HealthKit request explaining what is
  collected, why, and how long it is retained

**Texas (CUBI) and Washington (MY Health MY Data Act)**:
- Similar to BIPA; require informed consent and data deletion rights
- Already covered by HealthKit progressive authorization if done correctly

### 9.3 Medical Device Classification Avoidance

**FDA Digital Health Policy**: Apps that "diagnose" or "treat" conditions are medical devices.
Apps that provide "general wellness" information are not.

Safe framing (wellness): "Music personalized to how you're feeling today"
Unsafe framing (medical): "Detects stress levels and treats anxiety with music"

Rules:
1. Never use "detect", "diagnose", "treat", "clinical", or "medical" in any user-facing copy
2. Always show confidence scores and offer easy correction (already in the design)
3. Never store emotional readings as medical records — store as "music session preferences"
4. Add disclaimer in Settings: "MeloMo is not a medical device and does not provide
   medical advice. Biometric readings are personalization hints, not diagnoses."

### 9.4 Age Restrictions

- Recommend 17+ age rating in App Store Connect (HealthKit data from minors has additional
  legal requirements under COPPA; a 17+ rating sidesteps this without complex age-gating)
- Do not collect or store any HealthKit data from users who indicate they are under 18

### 9.5 Privacy Policy Requirements

The privacy policy must cover before any HealthKit feature ships:
- What HealthKit data is accessed and why
- Confirmation that raw biometric data never leaves the device
- What derived data (emotion coordinates) is transmitted and retained
- How long data is retained and how users can delete it
- Contact information for privacy inquiries
- GDPR: Data Controller identity and legal basis for processing
- CCPA: Sensitive data categories and user rights

---

## Part 10: Implementation Phases

### Pre-Phase Checklist (Before Writing a Line of Code)

- [ ] **Jamendo commercial license**: Email licensing@jamendo.com, get quote, budget it
- [ ] **YouTube decision**: Choose Option A (visible player) or Option B (drop YouTube)
- [ ] **Groq payment method**: Add billing info to Groq account (unlocks 10× rate limits)
- [ ] **Privacy policy draft**: Write before HealthKit feature ships (Phase 3)
- [ ] **DPIA started**: Begin EU data protection impact assessment
- [ ] **Analytics tool chosen**: PostHog or Firebase configured

---

### Phase 0 — Foundation (Week 1-2)
**Goal**: Working, crash-free app on a fast backend with one design system.

**Critical bug fixes**:
- `groq_service.py:37` — wrap `json.loads(raw)` in try/except, strip markdown fences before parse
- `BackendClient.swift:15` — replace `URL(string: "")!` force-unwrap with guard-let + precondition
- `AuthManager.swift:63-75` — delete fake Google user #else branch, show error instead
- `VibesView.swift:68` — wire "Current Vibe" card to `musicController.currentMood`
- `jamendo_service.py` / `youtube_service.py` — add `r.raise_for_status()` + error dict check
- `JamendoPlayer` — add `AVPlayerItem.didPlayToEndTimeNotification` for auto-advance
- `youtube_service.py` — change `safeSearch: "none"` to `safeSearch: "moderate"`

**YouTube compliance fix** (if keeping YouTube — Option A):
- Remove 1×1 hidden player. Show YouTube player at minimum 200×113px in NowPlayingView
- Update `YouTubePlaybackManager` to show controls, not hide them
- If dropping YouTube (Option B): delete `YouTubePlaybackManager.swift` entirely,
  remove YouTubePlayerKit dependency from Package.swift

**Design system**:
- Delete `ThemeColors` (electric blue/black) entirely
- `WarmMusicColors` is the single source of truth
- Delete dead components: `EnhancedMoodCard`, `CategoryFilterChip`, `generateSpotifyPlaylist`
- Delete dead `UserPreferences.favoriteMoods: [Mood]` (old type, orphaned)

**Backend migration**:
- Rewrite FastAPI → TypeScript/Hono on Cloudflare Workers
- Add CoreML on-device model for standard mood inputs (CreateML training: 2-3 hours)
- Configure Cloudflare KV for trending vibes (replaces unstable global Python list)
- Add simple `X-App-Key` header authentication (UUID stored in app bundle, prevents casual scraping)

**Analytics setup**:
- Install PostHog SDK (or Firebase Analytics)
- Instrument core funnel events: `app_open`, `onboarding_complete`, `first_session_complete`
- Configure anonymous session IDs — no PII

**Acceptance**: App launches without crashes. Backend responds in <200ms. One design system.
Auto-advance works for Jamendo. YouTube either shows visible player or is fully removed.
Analytics recording events.

---

### Phase 1 — Emotion Engine (Week 3-8)
**Goal**: The Resonance Wheel replaces the mood grid. ISO arc playlists work end-to-end.

**iOS changes**:
- New `EmotionCoordinate` struct: `{ valence: Float, arousal: Float, label: String }`
- `EnhancedMood` updated with `valence` and `arousal` fields
- `MoodCard` grid → `ResonanceWheel` `Canvas`-based 2-axis dial
- Destination emotion picker (second draggable point on wheel)
- `NowPlayingView`: arc progress indicator showing current position on emotional journey
- Two intent modes: Focus Mode (collapse) + Discovery Mode (expand)

**Backend changes**:
- Groq prompt updated with valence/arousal schema
- New ISO arc ordering algorithm: `order_by_arc(tracks, start_coord, end_coord)`
- Track coordinate estimation: BPM + genre → estimated valence/arousal
- Seed map updated to include valence/arousal range hints per mood

**Acceptance**: User drags wheel to stressed position, sets calm as destination, receives
a 12-track playlist that audibly progresses from energetic/tense toward calm. Arc
progress shows movement in NowPlayingView.

---

### Phase 2 — Resonance Design (Week 9-13)
**Goal**: The app looks and feels alive. Haptics, breathing visuals, dynamic backgrounds.

**iOS changes**:
- `ResonanceBackground` view: `MeshGradient` (iOS 18+) with valence-arousal color mapping,
  10s cross-fade. Fallback: animated `LinearGradient` for iOS 17 and earlier.
- `HapticEngine` manager: BPM-driven haptic patterns with genre-based sharpness
- `MusicController` broadcasts `currentBPM: Double` and `currentEnergy: Double` published properties
- Living vinyl: Canvas groove rendering + `AVAudioEngine.installTap()` for Jamendo audio levels
- Breathing typography: `.scaleEffect` + `.opacity` animation at BPM/4
- Reminiscence era prompt in onboarding + backend seed integration

**Acceptance**: Background color shifts visibly between a stressed track and a calm track.
Haptics present during playback. Vinyl breathes with audio dynamics. Fallback gradient
works correctly on an iOS 17 simulator.

---

### Phase 3 — Biometric Intelligence (Week 14-17)
**Goal**: HealthKit-driven emotion detection with honest confidence scoring.

**Pre-requisite**: Privacy policy must be drafted and reviewed before this phase ships.
BIPA consent screen must be designed and approved.

**iOS changes**:
- `BiometricSnapshot` model with confidence score + reasoning string
- `HealthKitManager` expanded: 7-day HRV baseline via `HKStatisticsQuery`, sleep analysis,
  activity state
- `HKObserverQuery` for background HR delivery
- BIPA/CCPA consent screen shown before first HealthKit authorization request
- Biometric snapshot UI: shows readings + confidence + "Does this feel right?" correction tap
- Medical device disclaimer added to Settings
- Emotion history stored in SwiftData with biometric context alongside journal entries

**Acceptance**: Magic Mood shows biometric readings with confidence %. User can override.
Emotional history in StatsView shows biometric context. HealthKit authorization only requested
after explicit consent screen. Disclaimer visible in Settings.

---

### Phase 4 — Offline Emotional Kits (Week 18-20)
**Prerequisite**: Jamendo commercial license signed and budgeted.
**Goal**: 40-minute offline playlist works with zero connectivity.

**iOS changes**:
- `OfflineKit` SwiftData model
- `KitDownloadManager`: batch download via `URLSession.backgroundConfiguration`
- Smart pre-load: usage heatmap pattern detection + Sunday pre-download trigger
- Settings: storage usage indicator, kit management (delete, download more)
- `JamendoPlayer` updated to prefer `localFileURL` over stream URL

**Acceptance**: User downloads kit, enables airplane mode, opens app → 40 min of
emotionally-sequenced music plays without connectivity.

---

### Phase 4b — TestFlight Beta (Week 20-21)
**Goal**: Real user validation before monetization goes live.

- Release to TestFlight: 50-100 beta users
- Instrument: session depth, arc completion rate, offline kit usage rate
- Key question: Do users play through the full arc, or stop after 2-3 tracks?
- Fix any critical UX issues before paywall is placed in front of the experience
- Gather qualitative feedback on Resonance Wheel usability

**Gate**: Do not launch Phase 5 (monetization) until arc completion rate >40% and
Day 7 retention >25% in beta cohort.

---

### Phase 5 — Monetization (Week 22-23)
**Depends on**: Phase 3 AND Phase 4 (biometrics and offline kits are both premium anchors).
**Goal**: Revenue infrastructure live. Premium gates in place.

**iOS changes**:
- RevenueCat SDK integration
- `PremiumManager` singleton: `isActive: Bool`, subscription state, offer codes
- Paywall view: annual plan highlighted, both options visible, 14-day/7-day trial CTAs
- Premium feature gates: offline kits (beyond starter), full arc length, biometric snapshot,
  Apple Music source, era personalization
- Soft paywall triggers: post-3rd-session banner, offline tap sheet, biometric history nudge
- Artist tip IAP products: $1.99, $4.99, $9.99 one-time purchases
- Analytics: instrument `paywall_shown`, `trial_started`, `subscription_purchased`

**Acceptance**: StoreKit 2 purchase completes end-to-end in sandbox. Premium features lock/unlock
correctly. Subscription persists across app reinstall. RevenueCat dashboard shows test purchase.
Grace period: Premium access is maintained during billing retry states.

---

### Phase 6 — Growth & B2B (Month 6+, after product is stable)
**Goal**: Diversified revenue. Micro-influencer pipeline. B2B offering live.

- Micro-influencer outreach: 20 creators in productivity/wellness niches
  (free premium + 30% affiliate commission tracked via RevenueCat offer codes +
  manual or PartnerStack commission payout)
- B2B landing page: melomo.app/business
- Organization dashboard: music usage patterns for HR teams (legal review required first —
  do not include individual emotional readings)
- Apply for Apple Small Business Program (manual application, not automatic)
- Jamendo artist tip disbursement: negotiate payout partner agreement

---

## Part 11: Cost vs. Revenue — The Full Picture

### 11.1 Monthly Infrastructure Cost by MRR Stage

| MRR Stage     | Est. DAU | CF Workers | Groq API | RevenueCat | Total Cost | Net Margin |
|--------------|----------|------------|----------|------------|------------|------------|
| $0 (launch)   | 0-500    | $0         | $0       | $0         | $0         | —          |
| $500 MRR      | ~1,000   | $0         | $0.25    | $0         | $0.25      | ~99.9%     |
| $2,500 MRR    | ~5,000   | $0         | $1.26    | $0         | $1.26      | ~99.9%     |
| $5,000 MRR    | ~10,000  | $0         | $2.52    | $25        | $27.52     | ~99.4%     |
| $10,000 MRR   | ~40,000  | $5         | $10      | $75        | $90        | ~99.1%     |
| $25,000 MRR   | ~100,000 | $5         | $25      | $200       | $230       | ~99.1%     |

Note: These are infrastructure costs BEFORE Apple's 30% cut and BEFORE any Jamendo commercial
license fee. Apple's cut is factored into MRR projections in Part 7.

### 11.2 Peak Demand Scenario (What Breaks First)

If a viral moment drives 10x DAU in a day:

| Service        | Normal Limit       | At 10x Spike (100k sudden DAU) | Risk           |
|---------------|--------------------|---------------------------------|----------------|
| CF Workers     | 100k/day free      | 1M requests → auto-scales       | Low ($0.27/M)  |
| Groq free tier | 14,400 req/day + 30 RPM | Hit RPM cap first — throttled | **Hard stop** |
| YouTube API    | Dropped (Option B) | N/A                             | None           |
| Jamendo API    | 50k calls/month    | Fine for day spike              | OK             |

**Peak mitigation strategy**:
1. Add payment method to Groq before any marketing push (unlocks ~300 RPM + 30k TPM)
2. Cloudflare Workers paid plan ($5/month) before any growth push → 10M req/day
3. Pre-cache popular mood combinations on Cloudflare KV

**Total cost of a viral day (100k DAU)**: ~$3-5 in Groq overage + $0.27 CF Workers = under $6.
Revenue from conversions on a viral day covers this hundreds of times over.

### 11.3 Revenue Milestones (Conservative Timeline)

| Milestone       | When (conservative)  | Trigger                                  |
|----------------|----------------------|------------------------------------------|
| First revenue   | Week 23              | StoreKit 2 live, first organic subscriber |
| $500 MRR        | Month 5-7            | Word-of-mouth from magic moments         |
| $2,500 MRR      | Month 7-9            | RevenueCat free tier ends here           |
| $5,000 MRR      | Month 10-14          | Micro-influencer pipeline active          |
| $10,000 MRR     | Month 15-20          | B2B + influencer + organic combined      |
| $25,000 MRR     | Month 20-30          | B2B at scale + content creator affiliate  |

These are base-case timelines for a solo developer with no existing audience.
With an existing audience or a strong influencer hit, compress by 40%.

---

## Part 12: App Store Strategy

### 12.1 App Store Compliance — Health Claims

Apple will reject any copy that implies medical benefit. Safe/unsafe examples:

| Unsafe (reject)                          | Safe (approve)                                      |
|-----------------------------------------|-----------------------------------------------------|
| "Reduces anxiety"                        | "Music to help you unwind"                          |
| "Treats depression"                      | "Music for your emotional state"                    |
| "Clinically proven stress relief"        | "Based on music therapy research"                   |
| "Scientifically proven ISO principle"    | "Inspired by music therapy research"                |
| "Improves HRV"                           | "Uses your heart rate to personalize your playlist" |
| "Medical-grade emotion detection"        | "Uses HealthKit biometrics to tune your music"      |

All paywall, onboarding, and store listing copy needs a review pass before submission.

### 12.2 App Store Optimization

- **Primary keyword**: "mood music" — high volume, moderate competition
- **Secondary**: "focus music", "sleep music", "emotion playlist", "wellness music"
- **Screenshots**: Show the Resonance Wheel first (unique UI = differentiation signal)
- **Preview video**: Show the arc visualization and haptic pulse in 30 seconds
- **Category**: Music (primary), Health & Fitness (secondary)
- **Age Rating**: 17+ (recommended — sidesteps COPPA complexity for HealthKit data)

### 12.3 Privacy — Data Handling

- Biometric data: stays on-device. Never transmitted to backend in raw form.
- Only inferred emotional coordinates (valence/arousal floats) sent to backend.
- Emotional history: stored in SwiftData (on-device). Never synced to backend.
- Vibe Sync (trending): anonymous mood + emoji only. No user ID attached.
- Privacy policy must explicitly state biometric data stays on device.
- App Store privacy label: HealthKit usage declared, no user tracking, no data selling.
- Analytics: anonymous session IDs only, no PII, no HealthKit data in analytics events.

---

## Part 13: Key Risks and Mitigations

| Risk                                    | Probability | Impact | Mitigation                                       |
|-----------------------------------------|------------|--------|--------------------------------------------------|
| Jamendo requires paid commercial license| **High**   | **High**| Negotiate before Phase 4. Budget the cost.      |
| Groq RPM throttle at concurrent users   | Medium     | Medium | Add payment method before launch; RPM unlocks   |
| YouTube ToS violation (if kept)         | **High**   | **High**| Show visible player or drop YouTube entirely    |
| YouTube quota exhausted                 | Medium     | High   | Drop YouTube (Option B) eliminates this entirely |
| App Review rejection for health claims  | Medium     | High   | Pre-review all copy against Apple guidelines    |
| B2B triggers medical device review      | Medium     | High   | Legal opinion before building; reframe as wellness |
| GDPR/BIPA enforcement for biometric data| Low-Med   | High   | DPIA + consent screen + on-device only storage  |
| Low premium conversion (<4%)           | Medium     | High   | A/B test paywall; adjust trial length; gate depth not breadth |
| Biometric detection feels inaccurate   | Medium     | Medium | Always show confidence + easy override          |
| iOS MeshGradient on iOS 17 and earlier | Low        | Low    | LinearGradient fallback already planned         |
| Artist tip payout not supported by Jamendo | Medium | Medium | Verify before building; delay if unsupported    |

---

## Part 14: Dependency Map and Build Order

```
PRE-PHASE: Commercial decisions (before any code)
  - Jamendo license negotiation
  - YouTube architecture decision (keep visible / drop)
  - Groq payment method activated
  - Analytics tool chosen

Phase 0: Foundation (Stabilize + Backend Migration)
  Fixes: 6 critical bugs + YouTube compliance
  Output: Crash-free app on Cloudflare Workers + analytics live

Phase 1: Emotion Engine (Core product identity)
  Depends on: Phase 0 complete
  Output: Resonance Wheel, ISO arc playlists, valence-arousal model

Phase 2: Resonance Design (Visual identity)
  Depends on: Phase 1 (needs valence/arousal per-track for color mapping)
  Output: MeshGradient backgrounds, BPM haptics, living vinyl

Phase 3: Biometric Intelligence
  Depends on: Phase 1 (needs emotion coordinates) + Privacy policy drafted
  Output: HealthKit-driven biometric snapshot with confidence scores + consent UI

Phase 4: Offline Kits  ──────────────────────┐
  Depends on: Phase 1 + Jamendo license       │ Can run in
Phase 4b: TestFlight Beta  ──────────────────┤ parallel
  Depends on: Phase 4 complete                │ after Phase 1
                                              │
Phase 5: Monetization (RevenueCat)  ──────────┘
  Depends on: Phase 3 AND Phase 4 AND Phase 4b gate met
  Output: Revenue live

Phase 6: Growth & B2B
  Depends on: Phase 5 live, product stable, legal review for B2B done
  Output: Micro-influencer pipeline, B2B dashboard
```

---

## Summary Checklist for Review

### Pre-Build (Before Phase 0)
- [ ] Email licensing@jamendo.com — get commercial license quote
- [ ] Decide: YouTube Option A (visible player) or Option B (drop YouTube)
- [ ] Add payment method to Groq account (unlocks 10× rate limits)
- [ ] Choose analytics tool (PostHog or Firebase) and create account
- [ ] Begin GDPR DPIA document
- [ ] Draft privacy policy (complete before Phase 3 ships)

### Technical Safety
- [ ] No raw biometric data sent to backend (only derived float coordinates)
- [ ] Groq API key not in iOS binary (backend-side only)
- [ ] YouTube API key not in iOS binary (backend-side only, or removed if Option B)
- [ ] Auth tokens for export never stored beyond single session
- [ ] RevenueCat receipt validation server-side (built into RevenueCat)
- [ ] HealthKit authorization requested progressively, never on launch
- [ ] BIPA consent screen shown before first HealthKit request
- [ ] Medical device disclaimer in Settings
- [ ] Grace period: Premium access maintained during billing retry states
- [ ] All 6 StoreKit 2 subscription states handled
- [ ] Groq response: JSON parse wrapped in try/catch, markdown fences stripped
- [ ] YouTube: visible player (Option A) or fully removed (Option B) — never 1×1 hidden

### Legal & Privacy
- [ ] GDPR DPIA completed before Phase 3 ships
- [ ] Privacy policy covers: HealthKit data, on-device storage, derived data, deletion rights
- [ ] CCPA "Do Not Sell or Share" mechanism in Settings
- [ ] BIPA written consent screen before biometric collection
- [ ] App Store 17+ age rating set
- [ ] Medical device disclaimer: "MeloMo is not a medical device"
- [ ] App Store Privacy Nutrition Label: HealthKit declared, analytics declared

### Business Safety
- [ ] Jamendo commercial license signed before building offline kits
- [ ] Jamendo tip payout partnership confirmed before building artist tips
- [ ] Artist tip economics communicated honestly (user pays $4.99 → artist gets $3.14)
- [ ] Apple Performance Partners removed from affiliate strategy (not applicable to own IAP)
- [ ] RevenueCat affiliate tracking: use external platform for commission disbursement
- [ ] B2B: legal opinion on medical device classification before building employer dashboard
- [ ] B2B: per-user opt-in required for any employer-visible emotional trend data
- [ ] Apple Small Business Program: apply manually after Year 1 (not automatic)

### Financial Safety
- [ ] Groq payment method added before any marketing campaign
- [ ] Cloudflare Workers $5/month paid plan before growth push
- [ ] RevenueCat MTR (not MRR) monitored — upgrade plan before $2,500 MTR
- [ ] Jamendo license cost added to break-even calculation after quote received
- [ ] Revenue milestones planned at 3% conversion rate (not 8%)
- [ ] Annual vs. monthly subscriber mix tracked for accurate MRR/cash flow projections

### Growth
- [ ] TestFlight beta: 50-100 users, measure arc completion rate before paywall launch
- [ ] Phase 5 gate: arc completion >40%, Day 7 retention >25% before monetization
- [ ] Analytics funnel instrumented before paywall goes live
- [ ] Micro-influencer affiliate: external tracking/payout platform configured

---

*Document version: 2.0 | Status: Safety-reviewed and corrected | Ready for execution*
