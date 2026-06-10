import Foundation
import UIKit
import MusicKit
import AVFAudio
import StoreKit
import os

// MARK: - MusicController
// Orchestrates playback + playlist generation across all providers.
// recentMoods / favoriteMoods use EnhancedMood so the UI never has to convert types.
// generate(for:) accepts EnhancedMood directly — the bridge conversion in EnhancedVibesView is gone.
private func getBroadGenre(_ mood: EnhancedMood) -> String {
    switch mood.category {
    case .energetic:              return mood.energy > 0.8 ? "upbeat pop dance" : "pop rock"
    case .relaxed, .chill:        return "chill indie ambient"
    case .emotional, .melancholy: return "indie ballad emotional"
    case .focused:                return "instrumental focus classical"
    case .social:                 return "party pop dance"
    default:                      return "popular music"
    }
}

@MainActor
final class MusicController: ObservableObject {
    // MARK: - Published Properties
    @Published var provider: Provider = {
        if let saved = UserDefaults.standard.string(forKey: "provider"),
           let p = Provider(rawValue: saved) { return p }
        return .appleMusic
    }() {
        didSet {
            UserDefaults.standard.set(provider.rawValue, forKey: "provider")
            updateStatistics()
        }
    }

    @Published var currentMood: EnhancedMood? = nil
    @Published var isAuthorizedForAppleMusic = false
    @Published var isOfflineMode = false
    @Published var lastGeneratedLink: PlaylistLink? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var userPreferences = UserPreferences()
    @Published var statistics = AppStatistics()
    @Published var recentMoods: [EnhancedMood] = []   // was [Mood] — migrated to EnhancedMood
    @Published var favoriteMoods: [EnhancedMood] = [] // was [Mood] — migrated to EnhancedMood
    @Published var currentTrackArtworkURL: URL? = nil
    @Published var playbackSource: PlaybackSource = .youtube
    @Published var jamendoPlayer = JamendoPlayer()
    @Published var youtubeManager = YouTubePlaybackManager()
    @Published var backendResponse: MoodGenerateResponse? = nil
    @Published var moodSuggestions: [MoodSuggestion] = []
    @Published var trendingVibes: [[String: String]] = []

    // MARK: - Private Properties
    private let log = Logger(subsystem: "com.melomo.app", category: "music")
    private let userDefaults = UserDefaults.standard
    private var lastGenerationTime: Date?

    // MARK: - Initialization
    init() {
        loadUserPreferences()
        loadStatistics()
        loadRecentMoods()
        loadFavoriteMoods()

        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Public Methods

    /**
     Generates a playlist from the backend based on the provided mood.
     
     This function sends a request to the backend to generate a playlist. The backend will then route the request to the appropriate music provider (Jamendo, YouTube, or Apple Music) based on the mood. If the backend is unavailable, it will fall back to the on-device NL classifier.
     
     - Parameter mood: The mood to generate a playlist for.
     */
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
        JournalManager.shared.logMood(title: mood.title, emoji: mood.emoji)
        Task { await BackendClient.shared.publishVibe(mood: mood.title, emoji: mood.emoji) }
        StreakManager.shared.recordActivity()   // consecutive-day streak
        statistics.totalPlaylistsGenerated += 1
        statistics.lastUsedDate = Date()
        saveStatistics()
        Haptics.moodSelected()

        do {
            let response = try await BackendClient.shared.generatePlaylist(input: mood.title)
            backendResponse = response
            moodSuggestions = response.topMoods

            // rawValue matching fails for "youtube" vs "YouTube" — lowercase switch is safer
            let source: PlaybackSource
            switch response.source.lowercased() {
            case "jamendo":     source = .jamendo
            case "apple_music": source = .appleMusic
            default:            source = .youtube
            }
            playbackSource = source

            let tracks = response.tracks.map { $0.toMusicTrack() }
            switch source {
            case .jamendo:
                jamendoPlayer.load(tracks: tracks)
            case .youtube:
                let videoIds = response.tracks.compactMap { $0.videoId }
                youtubeManager.load(tracks: tracks, videoIds: videoIds)
            case .appleMusic:
                // Apple Music flow unchanged — backend doesn't control MusicKit playback
                await generateAppleMusicPlaylist(mood: mood)
            }
            Haptics.playlistGenerated()
        } catch {
            // On backend failure, fall back to Apple Music search via on-device classifier
            if let fallbackTitle = MoodFallbackClassifier.classify(mood.title),
               let _ = enhancedMoods.first(where: { $0.title == fallbackTitle }) {
                errorMessage = "Using offline mode — backend unavailable"
                await generateAppleMusicPlaylist(mood: mood)
            } else {
                errorMessage = error.localizedDescription
                Haptics.error()
            }
        }
    }

    /**
     Generates a playlist from the backend based on the provided text input.
     
     This function sends a request to the backend to generate a playlist. The backend will then classify the text and generate a playlist based on the classified mood. This function runs in parallel with the on-device fallback in NLMoodInputView.
     
     - Parameter input: The text to generate a playlist for.
     */
    func generate(forText input: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await BackendClient.shared.generatePlaylist(input: input)
            backendResponse = response
            moodSuggestions = response.topMoods
        } catch {
            moodSuggestions = []    // Silent fallback — on-device classifier already handled the pick
        }
    }

    /**
     Generates a playlist based on the user's current biometrics (Magic Mood).
     */
    func generateMagicMood() async {
        guard !isLoading else { return }
        
        // Request HealthKit authorization if needed
        let authorized = await HealthKitManager.shared.requestAuthorization()
        guard authorized else {
            errorMessage = "HealthKit access required for Magic Mood."
            Haptics.error()
            return
        }

        isLoading = true
        defer { isLoading = false }
        
        do {
            let biometrics = await HealthKitManager.shared.fetchLatestBiometrics()
            // We use a generic "How do I feel?" prompt which the backend will enrich with biometric data
            let response = try await BackendClient.shared.generatePlaylist(input: "Detect my mood from biometrics", biometrics: biometrics)
            
            backendResponse = response
            moodSuggestions = response.topMoods
            
            // Map the returned mood to an EnhancedMood if possible, otherwise use fallback logic
            if let matchedMood = enhancedMoods.first(where: { $0.title.lowercased() == response.mood.lowercased() }) {
                currentMood = matchedMood
                addToRecentMoods(matchedMood)
                JournalManager.shared.logMood(title: matchedMood.title, emoji: matchedMood.emoji, biometrics: biometrics)
                Task { await BackendClient.shared.publishVibe(mood: matchedMood.title, emoji: matchedMood.emoji) }
            }
            
            let source: PlaybackSource
            switch response.source.lowercased() {
            case "jamendo":     source = .jamendo
            case "apple_music": source = .appleMusic
            default:            source = .youtube
            }
            playbackSource = source
            
            let tracks = response.tracks.map { $0.toMusicTrack() }
            switch source {
            case .jamendo:
                jamendoPlayer.load(tracks: tracks)
            case .youtube:
                let videoIds = response.tracks.compactMap { $0.videoId }
                youtubeManager.load(tracks: tracks, videoIds: videoIds)
            case .appleMusic:
                if let mood = currentMood {
                    await generateAppleMusicPlaylist(mood: mood)
                }
            }
            Haptics.playlistGenerated()
        } catch {
            errorMessage = "Magic Mood failed: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    func requestAuthorization() async { await refreshAuthorizationStatus() }

    func fetchTrendingVibes() async {
        trendingVibes = await BackendClient.shared.getTrendingVibes()
    }

    func downloadCurrentPlaylist() {
        guard playbackSource == .jamendo, let response = backendResponse else { return }
        
        for track in response.tracks {
            DownloadManager.shared.download(track.toMusicTrack())
        }
        Haptics.successPattern()
    }

    var isAuthorized: Bool { isAuthorizedForAppleMusic }

    var isPlaying: Bool {
        ApplicationMusicPlayer.shared.state.playbackStatus == .playing
    }

    func skipToNext() async {
        do {
            try await ApplicationMusicPlayer.shared.skipToNextEntry()
        } catch {
            log.error("Failed to skip forward: \(error.localizedDescription)")
        }
    }

    func skipToPrevious() async {
        do {
            try await ApplicationMusicPlayer.shared.skipToPreviousEntry()
        } catch {
            log.error("Failed to skip back: \(error.localizedDescription)")
        }
    }

    var currentPlayingTrack: MusicTrack? {
        guard let currentEntry = ApplicationMusicPlayer.shared.queue.currentEntry,
              let song = currentEntry.item as? Song else { return nil }

        // Try common artwork sizes — 300px is the sweet spot for card display
        let artworkURL = song.artwork?.url(width: 300, height: 300)
            ?? song.artwork?.url(width: 512, height: 512)
            ?? song.artwork?.url(width: 100, height: 100)

        return MusicTrack(
            id: song.id.rawValue,
            title: song.title,
            artist: song.artistName,
            album: song.albumTitle,
            artworkURL: artworkURL,
            duration: song.duration ?? 0,
            energy: currentMood?.energy ?? 0.5,
            genre: nil,
            mood: currentMood?.title
        )
    }

    // MARK: - Authorization

    /**
     Refreshes the authorization status for Apple Music.
     
     This function checks the current authorization status for Apple Music and updates the `isAuthorizedForAppleMusic` property accordingly. It also requests authorization if the status is not determined.
     */
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

    // MARK: - Mood Favorites

    func toggleFavorite(_ mood: EnhancedMood) {
        if let idx = favoriteMoods.firstIndex(where: { $0.id == mood.id }) {
            favoriteMoods.remove(at: idx)
            Haptics.light()
        } else {
            favoriteMoods.append(mood)
            Haptics.successPattern()
        }
        saveFavoriteMoods()
    }

    func isFavorite(_ mood: EnhancedMood) -> Bool {
        favoriteMoods.contains { $0.id == mood.id }
    }

    // MARK: - Mood Queries

    /// Fixed: was referencing nonexistent `allMoods` — use `enhancedMoods` global
    func getMoodsByCategory(_ category: MoodCategory) -> [EnhancedMood] {
        enhancedMoods.filter { $0.category == category }
    }

    func getPopularMoods() -> [EnhancedMood] {
        enhancedMoods.filter { $0.popularity >= 4 }
    }

    func getRandomMood() -> EnhancedMood? {
        // contains(where:) since EnhancedMood isn't Equatable
        let available = enhancedMoods.filter { m in !recentMoods.contains { $0.id == m.id } }
        return available.randomElement() ?? enhancedMoods.randomElement()
    }

    // MARK: - Private Generation

    private func generateAppleMusicPlaylist(mood: EnhancedMood) async {
        guard isAuthorizedForAppleMusic else {
            errorMessage = MeloMoError.authorizationFailed.errorDescription
            Haptics.error()
            return
        }

        do {
            let url = try await playAppleMusicPlaylist(mood: mood)
            lastGeneratedLink = .appleMusic(url)
            Haptics.playlistGenerated()
        } catch {
            let melomErr = error as? MeloMoError ?? .networkError
            errorMessage = melomErr.errorDescription
            log.error("Apple Music error: \(error.localizedDescription)")
            Haptics.error()
        }
    }

    private func generateSpotifyPlaylist(mood: EnhancedMood) async {
        let url = buildSpotifyHandoffURL(mood: mood)
        lastGeneratedLink = .spotify(url)
        log.info("Spotify handoff link generated for: \(mood.title)")
        Haptics.playlistGenerated()
        // Note: in-app Spotify playback requires their iOS SDK + OAuth — not worth the complexity
        errorMessage = "Spotify playlist ready! Tap the music bar to open Spotify."
    }

    private func generateYoutubeMusicPlaylist(mood: EnhancedMood) async {
        let url = buildYoutubeMusicURL(mood: mood)
        lastGeneratedLink = .youtubeMusic(url)

        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
            Haptics.playlistGenerated()
        } else {
            Haptics.warning()
        }
    }

    private func buildYoutubeMusicURL(mood: EnhancedMood) -> URL {
        let q = (mood.seeds + [mood.title, "music"]).joined(separator: " ")
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title

        return URL(string: "youtubemusic://search/\(encoded)")
            ?? URL(string: "https://music.youtube.com/search?q=\(encoded)")
            ?? URL(string: "https://music.youtube.com")!
    }

    private func playAppleMusicPlaylist(mood: EnhancedMood) async throws -> URL {
        log.info("Generating Apple Music playlist for: \(mood.title)")

        var songs: [Song] = []

        try await withThrowingTaskGroup(of: [Song].self) { group in
            // Strategy 1: original mood seeds
            let originalQuery = mood.seeds.joined(separator: " OR ")
            if !originalQuery.isEmpty {
                group.addTask {
                    var req = MusicCatalogSearchRequest(term: originalQuery, types: [Song.self])
                    req.limit = 25
                    guard let response = try? await req.response() else { return [] }
                    return Array(response.songs.prefix(25))
                }
            }

            // Strategy 2: mood title + "music"
            group.addTask {
                var req = MusicCatalogSearchRequest(term: "\(mood.title) music", types: [Song.self])
                req.limit = 25
                guard let response = try? await req.response() else { return [] }
                return Array(response.songs.prefix(25))
            }

            // Strategy 3: broad genre fallback
            group.addTask {
                var req = MusicCatalogSearchRequest(term: getBroadGenre(mood), types: [Song.self])
                req.limit = 25
                guard let response = try? await req.response() else { return [] }
                return Array(response.songs.prefix(25))
            }

            for try await searchedSongs in group {
                songs.append(contentsOf: searchedSongs)
            }
        }

        guard !songs.isEmpty else { throw MeloMoError.noResultsFound }
        guard MusicAuthorization.currentStatus == .authorized else { throw MeloMoError.authorizationFailed }

        let shuffled = songs.shuffled()
        currentTrackArtworkURL = shuffled.first?.artwork?.url(width: 300, height: 300)

        do {
            try await ApplicationMusicPlayer.shared.queue = .init(for: shuffled)
            try await ApplicationMusicPlayer.shared.play()
        } catch {
            log.error("MusicKit playback error: \(error.localizedDescription)")
            throw MeloMoError.networkError
        }

        // Shareable search URL for PlaylistLink storage
        let shareQuery = (mood.seeds.joined(separator: " OR ")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title
        return URL(string: "https://music.apple.com/search?term=\(shareQuery)")!
    }



    private func buildSpotifyHandoffURL(mood: EnhancedMood) -> URL {
        let q = (mood.seeds + [mood.title, "playlist"]).joined(separator: " ")
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title

        return URL(string: "spotify://search/\(encoded)")
            ?? URL(string: "https://open.spotify.com/search/\(encoded)")
            ?? URL(string: "https://open.spotify.com")!
    }

    // MARK: - Data Persistence

    private func loadUserPreferences() {
        guard let data = userDefaults.data(forKey: "userPreferences"),
              let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) else { return }
        userPreferences = prefs
    }

    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            userDefaults.set(data, forKey: "userPreferences")
        }
    }

    private func loadStatistics() {
        guard let data = userDefaults.data(forKey: "statistics"),
              let stats = try? JSONDecoder().decode(AppStatistics.self, from: data) else { return }
        statistics = stats
    }

    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(statistics) {
            userDefaults.set(data, forKey: "statistics")
        }
    }

    private func loadRecentMoods() {
        // Attempts [EnhancedMood] decode; silently drops stale [Mood] data on first launch after upgrade
        guard let data = userDefaults.data(forKey: "recentMoodsEnhanced"),
              let moods = try? JSONDecoder().decode([EnhancedMood].self, from: data) else { return }
        recentMoods = moods
    }

    private func saveRecentMoods() {
        if let data = try? JSONEncoder().encode(recentMoods) {
            userDefaults.set(data, forKey: "recentMoodsEnhanced")
        }
    }

    private func loadFavoriteMoods() {
        guard let data = userDefaults.data(forKey: "favoriteMoodsEnhanced"),
              let moods = try? JSONDecoder().decode([EnhancedMood].self, from: data) else { return }
        favoriteMoods = moods
    }

    private func saveFavoriteMoods() {
        if let data = try? JSONEncoder().encode(favoriteMoods) {
            userDefaults.set(data, forKey: "favoriteMoodsEnhanced")
        }
    }

    private func addToRecentMoods(_ mood: EnhancedMood) {
        recentMoods.removeAll { $0.id == mood.id }
        recentMoods.insert(mood, at: 0)
        if recentMoods.count > 10 { recentMoods = Array(recentMoods.prefix(10)) }
        saveRecentMoods()
    }

    private func updateStatistics() {
        statistics.mostUsedProvider = provider
        saveStatistics()
    }
}
