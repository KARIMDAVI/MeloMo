# MeloMo 🎵

**MeloMo** (Melody Mood) is an AI-powered music companion for iOS that matches your exact emotional state with the perfect soundtrack. Whether you're feeling "Electric," "Melancholy," or "Focused," MeloMo uses advanced AI to curate and play playlists for free—no subscription required.

![MeloMo Banner](melomo-design-reference.png)

## ✨ Key Features

- **🧠 AI Mood Engine**: Describe your vibe in natural language or use **Voice Input**. Our backend (powered by Groq LLM) classifies your mood and suggests the perfect tracks.
- **💓 Biometric Harmony**: Integrates with **HealthKit** to analyze your heart rate, HRV, and sleep patterns, suggesting music that helps you recover or stay energized.
- **🚀 One-Tap Export**: Clone your favorite mood playlists directly to **Spotify**, **Apple Music**, or **YouTube Music** with a single tap.
- **🎨 Warm Music Design System**: A stunning, mood-reactive UI featuring:
  - **Liquid Glass** components and frosted backgrounds.
  - **Dynamic Gradients** that shift colors based on the current mood.
  - **Fluid Animations** (60 FPS) and haptic feedback.
- **📈 Stats & Streaks**: Track your musical journey, maintain daily streaks, and visualize your mood trends over time.

## 🛠 Tech Stack

### iOS Application
- **Framework**: SwiftUI (100%)
- **Persistence**: SwiftData
- **Playback**: AVPlayer (Jamendo) & YouTubePlayerKit
- **Integration**: MusicKit (Apple Music Export), HealthKit (Biometrics)
- **Authentication**: Google Sign-In & Firebase

### Backend Services
- **Framework**: FastAPI (Python)
- **AI/LLM**: Groq (Llama 3) for mood classification
- **APIs**: Jamendo API (Free Audio), YouTube Data API (Music Discovery)
- **Caching**: Optimized metadata fetching for fast playback

## 🚦 Getting Started

### Backend Setup
1. Navigate to `/backend`.
2. Configure `.env` with your API keys (Groq, Jamendo, YouTube).
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Start the server:
   ```bash
   uvicorn main:app --reload
   ```

### iOS App Setup
1. Open `MeloMo.xcodeproj` in Xcode 15+.
2. Ensure you have a valid Development Team for HealthKit and MusicKit capabilities.
3. Update the `BackendClient.swift` with your local or hosted backend URL.
4. Build and run on a physical device for the best experience (required for HealthKit).

## 📂 Project Structure

- `MeloMo/`: Core iOS application source.
  - `Views/`: SwiftUI screens (Vibes, Now Playing, Library, Stats).
  - `Managers/`: Logic for Auth, HealthKit, Music Playback, and Exports.
  - `Components/`: Reusable "Warm Music" UI elements.
- `backend/`: Python FastAPI service.
  - `routers/`: Mood classification and playlist generation.
  - `services/`: API wrappers for Groq, Jamendo, and YouTube.
- `docs/`: Technical specifications and design system plans.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Created with ❤️ by K!MO. Elevate your mood, one melody at a time.*
