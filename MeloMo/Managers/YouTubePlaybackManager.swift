// YouTubePlaybackManager.swift
// Coordinator between MusicController and YouTubePlayerKit.
// YouTubePlayerKit renders via a SwiftUI view — this manager holds the queue and exposes controls.
// The actual YouTubePlayerView is embedded in NowPlayingView (source must be set here).
import YouTubePlayerKit

@MainActor
final class YouTubePlaybackManager: ObservableObject {
    @Published var currentTrack: MusicTrack?
    @Published var isPlaying = false

    // autoPlay: true so loading a video starts immediately without user tap
    // showControls: false because NowPlayingView provides its own playback controls
    // autoPlay/showControls live on Parameters, not Configuration (v2 API change)
    let player = YouTubePlayer(parameters: .init(autoPlay: true, showControls: false))

    private var queue: [MusicTrack] = []
    private var videoIds: [String] = []
    private var currentIndex = 0

    func load(tracks: [MusicTrack], videoIds: [String]) {
        self.queue = tracks
        self.videoIds = videoIds
        currentIndex = 0
        playCurrentTrack()
    }

    func play()  { Task { try? await player.play() };  isPlaying = true }
    func pause() { Task { try? await player.pause() }; isPlaying = false }

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

    private func playCurrentTrack() {
        guard currentIndex < videoIds.count else { return }
        currentTrack = queue[safe: currentIndex]
        player.source = .video(id: videoIds[currentIndex])
        isPlaying = true
    }
}

// Safe subscript — one utility, lives here where it's first needed
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
