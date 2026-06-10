// SavedPlaylist.swift
// SwiftData model for persisting user-saved playlists.
// Decision: SwiftData over Core Data — less boilerplate, native Swift syntax, iOS 17+ only.
// Why a separate model from MusicTrack? Playlists outlive app sessions; tracks are ephemeral UI state.
import Foundation
import SwiftData

@Model
final class SavedPlaylist {
    var id: String
    var name: String
    var moodTitle: String
    var moodEmoji: String
    var providerRaw: String      // Provider.rawValue — stored as string to avoid enum migration headaches
    var trackCount: Int
    var createdAt: Date
    var trackData: Data          // JSON-encoded [MusicTrack] — flat storage avoids SwiftData relationship complexity
    var exportedTo: [String]     // destination keys: "spotify", "apple_music", "youtube_music"

    init(
        id: String = UUID().uuidString,
        name: String,
        moodTitle: String,
        moodEmoji: String,
        provider: Provider,
        tracks: [MusicTrack],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.moodTitle = moodTitle
        self.moodEmoji = moodEmoji
        self.providerRaw = provider.rawValue
        self.trackCount = tracks.count
        self.createdAt = createdAt
        self.exportedTo = []
        self.trackData = (try? JSONEncoder().encode(tracks)) ?? Data()
    }

    var provider: Provider? { Provider(rawValue: providerRaw) }

    var tracks: [MusicTrack] {
        (try? JSONDecoder().decode([MusicTrack].self, from: trackData)) ?? []
    }
}
