// JamendoPlayer.swift
// AVPlayer wrapper for Jamendo .mp3 stream URLs.
// Jamendo streams are direct HTTP URLs (no DRM, no auth token) — AVPlayer handles natively.
// Decision: not using AVQueuePlayer because we want per-track skip control and artwork updates.
import AVFoundation

@MainActor
final class JamendoPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: MusicTrack?

    private var player: AVPlayer?
    private var queue: [MusicTrack] = []
    private var currentIndex = 0

    func load(tracks: [MusicTrack]) {
        // Only keep tracks that have a playable URL — Jamendo occasionally returns nulls
        queue = tracks.filter { $0.streamURL != nil }
        currentIndex = 0
        playCurrentTrack()
    }

    func play()  { player?.play();  isPlaying = true }
    func pause() { player?.pause(); isPlaying = false }

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
        guard currentIndex < queue.count else { return }
        let track = queue[currentIndex]
        currentTrack = track
        
        let url: URL
        if let local = DownloadManager.shared.localURL(for: track.id) {
            url = local
        } else if let stream = track.streamURL {
            url = stream
        } else {
            return
        }
        
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
    }
}
