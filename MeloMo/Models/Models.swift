import Foundation

// MARK: - Music Provider
enum Provider: String, CaseIterable, Identifiable, Codable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case youtubeMusic = "YouTube Music"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .appleMusic: return "music.note"
        case .spotify: return "music.note.list"
        case .youtubeMusic: return "play.rectangle"
        }
    }
    
    var color: String {
        switch self {
        case .appleMusic: return "pink"
        case .spotify: return "green"
        case .youtubeMusic: return "red"
        }
    }
}

// MARK: - Mood Structure
struct Mood: Identifiable, Hashable, Codable {
    let id = UUID()
    let emoji: String
    let imageName: String
    let title: String
    let description: String
    /// Keywords/genres we use to search
    let seeds: [String]
    /// A light/dark energy hint for sorting tracks (0.0 - 1.0)
    let energy: Double
    /// Mood category for grouping
    let category: MoodCategory
    /// Popularity/trending score
    let popularity: Int
    
    init(emoji: String, imageName: String = "", title: String, description: String = "", seeds: [String], energy: Double, category: MoodCategory = .general, popularity: Int = 1) {
        self.emoji = emoji
        self.imageName = imageName
        self.title = title
        self.description = description
        self.seeds = seeds
        self.energy = energy
        self.category = category
        self.popularity = popularity
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case emoji, imageName, title, description, seeds, energy, category, popularity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        emoji = try container.decode(String.self, forKey: .emoji)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? ""
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        seeds = try container.decode([String].self, forKey: .seeds)
        energy = try container.decode(Double.self, forKey: .energy)
        category = try container.decode(MoodCategory.self, forKey: .category)
        popularity = try container.decode(Int.self, forKey: .popularity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(seeds, forKey: .seeds)
        try container.encode(energy, forKey: .energy)
        try container.encode(category, forKey: .category)
        try container.encode(popularity, forKey: .popularity)
    }
}

// MARK: - Mood Categories
enum MoodCategory: String, CaseIterable, Identifiable, Codable {
    case energetic = "Energetic"
    case relaxed = "Relaxed"
    case emotional = "Emotional"
    case focused = "Focused"
    case social = "Social"
    case general = "General"
    case melancholy = "Melancholy"
    case chill = "Chill"
    case romantic = "Romantic"
    case magical = "Magical"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .energetic: return "bolt.fill"
        case .relaxed: return "leaf.fill"
        case .emotional: return "heart.fill"
        case .focused: return "brain.head.profile"
        case .social: return "person.2.fill"
        case .general: return "star.fill"
        case .melancholy: return "cloud.rain.fill"
        case .chill: return "leaf.fill"
        case .romantic: return "heart.fill"
        case .magical: return "sparkles"
        }
    }
}

// MARK: - Playlist Link
enum PlaylistLink: Equatable, Codable {
    case appleMusic(URL)
    case spotify(URL)
    case youtubeMusic(URL)
    
    var url: URL {
        switch self {
        case .appleMusic(let url), .spotify(let url), .youtubeMusic(let url):
            return url
        }
    }
    
    var provider: Provider {
        switch self {
        case .appleMusic: return .appleMusic
        case .spotify: return .spotify
        case .youtubeMusic: return .youtubeMusic
        }
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case type, url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let url = try container.decode(URL.self, forKey: .url)
        
        switch type {
        case "appleMusic":
            self = .appleMusic(url)
        case "spotify":
            self = .spotify(url)
        case "youtubeMusic":
            self = .youtubeMusic(url)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown provider type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .appleMusic(let url):
            try container.encode("appleMusic", forKey: .type)
            try container.encode(url, forKey: .url)
        case .spotify(let url):
            try container.encode("spotify", forKey: .type)
            try container.encode(url, forKey: .url)
        case .youtubeMusic(let url):
            try container.encode("youtubeMusic", forKey: .type)
            try container.encode(url, forKey: .url)
        }
    }
}

// MARK: - Music Track
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
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, artworkURL, duration, energy, genre, mood
    }
    
    init(id: String, title: String, artist: String, album: String? = nil, artworkURL: URL? = nil, duration: TimeInterval, energy: Double, genre: String? = nil, mood: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkURL = artworkURL
        self.duration = duration
        self.energy = energy
        self.genre = genre
        self.mood = mood
    }
}

// MARK: - Playlist
struct Playlist: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let tracks: [MusicTrack]
    let mood: Mood
    let provider: Provider
    let createdAt: Date
    let totalDuration: TimeInterval
    
    var trackCount: Int { tracks.count }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, name, description, tracks, mood, provider, createdAt, totalDuration
    }
    
    init(id: String, name: String, description: String? = nil, tracks: [MusicTrack], mood: Mood, provider: Provider, createdAt: Date = Date(), totalDuration: TimeInterval = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.tracks = tracks
        self.mood = mood
        self.provider = provider
        self.createdAt = createdAt
        self.totalDuration = totalDuration
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var favoriteMoods: [Mood]
    var preferredProvider: Provider
    var autoPlay: Bool
    var notificationsEnabled: Bool
    var theme: AppTheme
    
    init() {
        self.favoriteMoods = []
        self.preferredProvider = .appleMusic
        self.autoPlay = true
        self.notificationsEnabled = true
        self.theme = .system
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { rawValue }
}

// MARK: - App Statistics
struct AppStatistics: Codable {
    var totalPlaylistsGenerated: Int
    var favoriteMood: Mood?
    var totalListeningTime: TimeInterval
    var mostUsedProvider: Provider
    var lastUsedDate: Date?
    
    init() {
        self.totalPlaylistsGenerated = 0
        self.favoriteMood = nil
        self.totalListeningTime = 0
        self.mostUsedProvider = .appleMusic
        self.lastUsedDate = nil
    }
}

// MARK: - Error Types
enum MeloMoError: LocalizedError {
    case authorizationFailed
    case networkError
    case noResultsFound
    case invalidMood
    case providerUnavailable
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Music service authorization failed. Please check your permissions."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .noResultsFound:
            return "No music found for this mood. Try a different mood or search terms."
        case .invalidMood:
            return "Invalid mood selection. Please try again."
        case .providerUnavailable:
            return "Music service is currently unavailable. Please try again later."
        }
    }
}
