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
