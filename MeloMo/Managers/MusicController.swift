import Foundation
import UIKit
import MusicKit
import AVFAudio
import StoreKit
import os

@MainActor
final class MusicController: ObservableObject {
    // MARK: - Published Properties
    @Published var provider: Provider = {
        if let savedProvider = UserDefaults.standard.string(forKey: "provider"),
           let provider = Provider(rawValue: savedProvider) {
            return provider
        }
        return .appleMusic
    }() {
        didSet { 
            UserDefaults.standard.set(provider.rawValue, forKey: "provider")
            updateStatistics()
        }
    }
    
    @Published var currentMood: Mood? = nil
    @Published var isAuthorizedForAppleMusic = false
    @Published var lastGeneratedLink: PlaylistLink? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var userPreferences = UserPreferences()
    @Published var statistics = AppStatistics()
    @Published var recentMoods: [Mood] = []
    @Published var favoriteMoods: [Mood] = []
    @Published var currentTrackArtworkURL: URL? = nil
    
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
        
        // Initialize Apple Music authorization status
        Task {
            await refreshAuthorizationStatus()
        }
    }
    
    // MARK: - Public Methods
    
    /// Generate & play (Apple Music) or handoff (Spotify)
    func generate(for mood: Mood) async {
        guard !isLoading else { 
            Haptics.warning()
            return 
        }
        
        // Prevent rapid successive generations
        if let lastTime = lastGenerationTime,
           Date().timeIntervalSince(lastTime) < 2.0 {
            Haptics.warning()
            return
        }
        
        currentMood = mood
        errorMessage = nil
        isLoading = true
        lastGenerationTime = Date()
        
        defer { isLoading = false }
        
        // Add to recent moods
        addToRecentMoods(mood)
        
        // Update statistics
        statistics.totalPlaylistsGenerated += 1
        statistics.lastUsedDate = Date()
        statistics.mostUsedProvider = provider
        saveStatistics()
        
        Haptics.moodSelected()
        
        switch provider {
        case .appleMusic:
            await generateAppleMusicPlaylist(mood: mood)
        case .spotify:
            await generateSpotifyPlaylist(mood: mood)
        case .youtubeMusic:
            await generateYoutubeMusicPlaylist(mood: mood)
        }
    }
    
    /// Request Apple Music authorization
    func requestAuthorization() async {
        await refreshAuthorizationStatus()
    }
    
    /// Check if Apple Music is authorized
    var isAuthorized: Bool {
        return isAuthorizedForAppleMusic
    }
    
    /// Check if music is currently playing
    var isPlaying: Bool {
        return ApplicationMusicPlayer.shared.state.playbackStatus == .playing
    }
    
    /// Skip to next track
    func skipToNext() async {
        do {
            try await ApplicationMusicPlayer.shared.skipToNextEntry()
            log.info("Skipped to next track")
        } catch {
            log.error("Failed to skip to next track: \(error.localizedDescription)")
        }
    }
    
    /// Skip to previous track
    func skipToPrevious() async {
        do {
            try await ApplicationMusicPlayer.shared.skipToPreviousEntry()
            log.info("Skipped to previous track")
        } catch {
            log.error("Failed to skip to previous track: \(error.localizedDescription)")
        }
    }
    
    /// Get current playing song information
    var currentPlayingTrack: MusicTrack? {
        guard let currentEntry = ApplicationMusicPlayer.shared.queue.currentEntry,
              let song = currentEntry.item as? Song else {
            log.debug("No current track available from Apple Music player")
            return nil
        }
        
        log.info("🎵 Getting track info for: \(song.title) by \(song.artistName)")
        
        // The issue might be that we need to access the artwork differently
        // Let's try a more direct approach
        var artworkURL: URL? = nil
        
        if let artwork = song.artwork {
            log.info("✅ Song HAS artwork property")
            log.info("📐 Artwork max dimensions: \(artwork.maximumWidth)x\(artwork.maximumHeight)")
            
            // Try the most common sizes that Apple Music supports
            artworkURL = artwork.url(width: 300, height: 300)
            log.info("🖼️ 300x300 URL: \(artworkURL?.absoluteString ?? "nil")")
            
            if artworkURL == nil {
                artworkURL = artwork.url(width: 512, height: 512)
                log.info("🖼️ 512x512 URL: \(artworkURL?.absoluteString ?? "nil")")
            }
            
            if artworkURL == nil {
                artworkURL = artwork.url(width: 200, height: 200)
                log.info("🖼️ 200x200 URL: \(artworkURL?.absoluteString ?? "nil")")
            }
            
            if artworkURL == nil {
                artworkURL = artwork.url(width: 100, height: 100)
                log.info("🖼️ 100x100 URL: \(artworkURL?.absoluteString ?? "nil")")
            }
        } else {
            log.error("❌ Song has NO artwork property at all")
        }
        
        log.info("🎨 FINAL ARTWORK URL: \(artworkURL?.absoluteString ?? "NONE FOUND")")
        
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
    
    
    /// Refresh Apple Music authorization status
    func refreshAuthorizationStatus() async {
        do {
            switch MusicAuthorization.currentStatus {
            case .authorized: 
                isAuthorizedForAppleMusic = true
                Haptics.successPattern()
            case .notDetermined:
                let status = await MusicAuthorization.request()
                isAuthorizedForAppleMusic = (status == .authorized)
                if isAuthorizedForAppleMusic {
                    Haptics.successPattern()
                } else {
                    Haptics.error()
                }
            default: 
                isAuthorizedForAppleMusic = false
                Haptics.error()
            }
        } catch {
            log.error("Authorization error: \(error.localizedDescription)")
            isAuthorizedForAppleMusic = false
            Haptics.error()
        }
    }
    
    /// Toggle favorite status for a mood
    func toggleFavorite(_ mood: Mood) {
        if let index = favoriteMoods.firstIndex(where: { $0.id == mood.id }) {
            favoriteMoods.remove(at: index)
            Haptics.light()
        } else {
            favoriteMoods.append(mood)
            Haptics.successPattern()
        }
        saveFavoriteMoods()
    }
    
    /// Check if a mood is favorited
    func isFavorite(_ mood: Mood) -> Bool {
        return favoriteMoods.contains { $0.id == mood.id }
    }
    
    /// Get moods by category
    func getMoodsByCategory(_ category: MoodCategory) -> [Mood] {
        return allMoods.filter { $0.category == category }
    }
    
    /// Get popular moods
    func getPopularMoods() -> [Mood] {
        return allMoods.filter { $0.popularity >= 4 }
    }
    
    /// Get random mood for discovery
    func getRandomMood() -> Mood? {
        let availableMoods = allMoods.filter { !recentMoods.contains($0) }
        return availableMoods.randomElement() ?? allMoods.randomElement()
    }
    
    // MARK: - Private Methods
    
    private func generateAppleMusicPlaylist(mood: Mood) async {
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
            let error = error as? MeloMoError ?? .networkError
            errorMessage = error.errorDescription
            log.error("Apple Music error: \(error.localizedDescription)")
            Haptics.error()
        }
    }
    
    private func generateSpotifyPlaylist(mood: Mood) async {
        let url = buildSpotifyHandoffURL(mood: mood)
        lastGeneratedLink = .spotify(url)
        
        // For now, just generate the link without auto-opening Spotify
        // User can manually tap to open when ready
        log.info("Generated Spotify playlist link for mood: \(mood.title)")
        Haptics.playlistGenerated()
        
        // Note: In-app Spotify playback would require Spotify iOS SDK
        // and proper authentication setup which is complex
        errorMessage = "Spotify playlist ready! Tap the music bar to open Spotify."
    }
    
    private func generateYoutubeMusicPlaylist(mood: Mood) async {
        let url = buildYoutubeMusicURL(mood: mood)
        lastGeneratedLink = .youtubeMusic(url)
        
        // open YouTube Music if available, else show share
        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
            Haptics.playlistGenerated()
        } else {
            Haptics.warning()
        }
    }
    
    private func buildYoutubeMusicURL(mood: Mood) -> URL {
        let q = (mood.seeds + [mood.title, "music"]).joined(separator: " ")
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title
        
        // YouTube Music deep link
        guard let url = URL(string: "youtubemusic://search/\(encoded)") else {
            // Fallback to web search if deep link fails
            let webQuery = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title
            return URL(string: "https://music.youtube.com/search?q=\(webQuery)") ?? URL(string: "https://music.youtube.com")!
        }
        return url
    }
    
    /// Build a basic Apple Music play queue from catalog search.
    private func playAppleMusicPlaylist(mood: Mood) async throws -> URL {
        log.info("Generating Apple Music playlist for mood: \(mood.title)")
        
        // Try multiple search strategies
        var songs: [Song] = []
        
        // Strategy 1: Use original mood seeds
        let originalQuery = mood.seeds.joined(separator: " OR ")
        if !originalQuery.isEmpty {
            log.info("Trying original seeds: \(originalQuery)")
            var req = MusicCatalogSearchRequest(term: originalQuery, types: [Song.self])
            req.limit = 25
            
            do {
                let response = try await req.response()
                songs = Array(response.songs.prefix(25))
                log.info("Found \(songs.count) songs with original seeds")
            } catch {
                log.warning("Original seeds search failed: \(error.localizedDescription)")
            }
        }
        
        // Strategy 2: If no results, try simplified search with mood title + generic terms
        if songs.isEmpty {
            let fallbackQuery = "\(mood.title) music"
            log.info("Trying fallback search: \(fallbackQuery)")
            var req = MusicCatalogSearchRequest(term: fallbackQuery, types: [Song.self])
            req.limit = 25
            
            do {
                let response = try await req.response()
                songs = Array(response.songs.prefix(25))
                log.info("Found \(songs.count) songs with fallback search")
            } catch {
                log.warning("Fallback search failed: \(error.localizedDescription)")
            }
        }
        
        // Strategy 3: If still no results, try broad genre-based search
        if songs.isEmpty {
            let broadQuery = getBroadGenreForMood(mood)
            log.info("Trying broad genre search: \(broadQuery)")
            var req = MusicCatalogSearchRequest(term: broadQuery, types: [Song.self])
            req.limit = 25
            
            do {
                let response = try await req.response()
                songs = Array(response.songs.prefix(25))
                log.info("Found \(songs.count) songs with broad genre search")
            } catch {
                log.warning("Broad genre search failed: \(error.localizedDescription)")
            }
        }
        
        // Final check
        guard !songs.isEmpty else {
            log.error("All search strategies failed for mood: \(mood.title)")
            throw MeloMoError.noResultsFound
        }

        // Check Apple Music authorization for songs
        guard MusicAuthorization.currentStatus == .authorized else {
            log.error("Apple Music not authorized — cannot play")
            throw MeloMoError.authorizationFailed
        }

        // Store the first song's artwork for the music bar
        let firstSong = songs.shuffled().first!
        let firstSongArtworkURL = firstSong.artwork?.url(width: 300, height: 300)
        log.info("🎨 STORING FIRST SONG ARTWORK: \(firstSongArtworkURL?.absoluteString ?? "nil")")
        
        // Shuffle and play
        let sorted = songs.shuffled()
        do {
            try await ApplicationMusicPlayer.shared.queue = .init(for: sorted)
            try await ApplicationMusicPlayer.shared.play()
            log.info("Successfully started playbook for mood: \(mood.title)")
            
            // Store artwork URL for music bar display
            currentTrackArtworkURL = firstSongArtworkURL
            if let artworkURL = firstSongArtworkURL {
                log.info("✅ ARTWORK STORED FOR MUSIC BAR: \(artworkURL.absoluteString)")
            } else {
                log.error("❌ NO ARTWORK TO STORE FOR MUSIC BAR")
            }
        } catch {
            log.error("MusicKit playback error: \(error.localizedDescription)")
            throw MeloMoError.networkError
        }
        
        // Fallback: create a search URL for sharing
        let shareQuery = originalQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title
        let url = URL(string: "https://music.apple.com/search?term=\(shareQuery)")!
        return url
    }
    
    /// Get broad genre terms for difficult moods
    private func getBroadGenreForMood(_ mood: Mood) -> String {
        switch mood.category {
        case .energetic:
            return mood.energy > 0.8 ? "upbeat pop dance" : "pop rock"
        case .relaxed, .chill:
            return "chill indie ambient"
        case .emotional, .melancholy:
            return "indie ballad emotional"
        case .focused:
            return "instrumental focus classical"
        case .social:
            return "party pop dance"
        default:
            return "popular music"
        }
    }

    /// Spotify: lean handoff via search (no SDK token needed).
    private func buildSpotifyHandoffURL(mood: Mood) -> URL {
        let q = (mood.seeds + [mood.title, "playlist"]).joined(separator: " ")
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title
        
        // deep link to Spotify search
        guard let url = URL(string: "spotify://search/\(encoded)") else {
            // Fallback to web search if deep link fails
            let webQuery = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mood.title
            return URL(string: "https://open.spotify.com/search/\(webQuery)") ?? URL(string: "https://open.spotify.com")!
        }
        return url
    }
    
    // MARK: - Data Persistence
    
    private func loadUserPreferences() {
        if let data = userDefaults.data(forKey: "userPreferences"),
           let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = prefs
        }
    }
    
    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            userDefaults.set(data, forKey: "userPreferences")
        }
    }
    
    private func loadStatistics() {
        if let data = userDefaults.data(forKey: "statistics"),
           let stats = try? JSONDecoder().decode(AppStatistics.self, from: data) {
            statistics = stats
        }
    }
    
    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(statistics) {
            userDefaults.set(data, forKey: "statistics")
        }
    }
    
    private func loadRecentMoods() {
        if let data = userDefaults.data(forKey: "recentMoods"),
           let moods = try? JSONDecoder().decode([Mood].self, from: data) {
            recentMoods = moods
        }
    }
    
    private func saveRecentMoods() {
        if let data = try? JSONEncoder().encode(recentMoods) {
            userDefaults.set(data, forKey: "recentMoods")
        }
    }
    
    private func loadFavoriteMoods() {
        if let data = userDefaults.data(forKey: "favoriteMoods"),
           let moods = try? JSONDecoder().decode([Mood].self, from: data) {
            favoriteMoods = moods
        }
    }
    
    private func saveFavoriteMoods() {
        if let data = try? JSONEncoder().encode(favoriteMoods) {
            userDefaults.set(data, forKey: "favoriteMoods")
        }
    }
    
    private func addToRecentMoods(_ mood: Mood) {
        // Remove if already exists
        recentMoods.removeAll { $0.id == mood.id }
        
        // Add to beginning
        recentMoods.insert(mood, at: 0)
        
        // Keep only last 10
        if recentMoods.count > 10 {
            recentMoods = Array(recentMoods.prefix(10))
        }
        
        saveRecentMoods()
    }
    
    private func updateStatistics() {
        statistics.mostUsedProvider = provider
        saveStatistics()
    }
}
