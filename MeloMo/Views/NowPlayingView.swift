// NowPlayingView.swift — Full-screen now playing experience.
// Hosts the hidden YouTubePlayerView (1x1px, drives audio) for YouTube source.
// Jamendo and Apple Music show artwork only — AVPlayer/MusicKit run in background.
import SwiftUI
import YouTubePlayerKit
import FontAwesome
import MusicKit

struct NowPlayingView: View {
    @EnvironmentObject private var musicController: MusicController
    @State private var showExportSheet = false

    private var currentTrack: MusicTrack? {
        switch musicController.playbackSource {
        case .jamendo:    return musicController.jamendoPlayer.currentTrack
        case .youtube:    return musicController.youtubeManager.currentTrack
        case .appleMusic: return musicController.currentPlayingTrack
        }
    }

    private var isPlaying: Bool {
        switch musicController.playbackSource {
        case .jamendo:    return musicController.jamendoPlayer.isPlaying
        case .youtube:    return musicController.youtubeManager.isPlaying
        case .appleMusic: return musicController.isPlaying
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                // YouTube player must exist in the view hierarchy to drive audio
                // 1x1 at near-zero opacity — present but invisible
                if musicController.playbackSource == .youtube {
                    YouTubePlayerView(musicController.youtubeManager.player)
                        .frame(width: 1, height: 1)
                        .opacity(0.001)
                }

                Spacer()
                artworkSection
                trackInfoSection
                controlsSection

                if let reason = currentTrack?.matchReason {
                    WhyThisSongView(reason: reason)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                Button(action: { showExportSheet = true }) {
                    HStack(spacing: 8) {
                        Text(Icons.export)
                            .font(Font.fontAwesome(ofSize: 16, style: .solid))
                        Text("Clone to your app")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheetView(playlistName: "\(currentTrack?.mood ?? "My") Playlist")
                .environmentObject(musicController)
        }
    }

    private var artworkSection: some View {
        AsyncImage(url: currentTrack?.artworkURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.white.opacity(0.08)
        }
        .frame(width: 260, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.5), radius: 30)
        .padding(.bottom, 28)
    }

    private var trackInfoSection: some View {
        VStack(spacing: 4) {
            Text(currentTrack?.title ?? "Now Playing")
                .font(.title3).fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            Text(currentTrack?.artist ?? "")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 24)
    }

    private var controlsSection: some View {
        HStack(spacing: 44) {
            controlButton(icon: Icons.skipPrev) { skipPrevious() }
            controlButton(icon: isPlaying ? Icons.pause : Icons.play, size: 44) { togglePlay() }
            controlButton(icon: Icons.skipNext) { skipNext() }
        }
        .padding(.bottom, 16)
    }

    private func controlButton(icon: String, size: CGFloat = 28, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(icon)
                .font(Font.fontAwesome(ofSize: size, style: .solid))
                .foregroundColor(.white)
        }
    }

    private func togglePlay() {
        switch musicController.playbackSource {
        case .jamendo:
            isPlaying ? musicController.jamendoPlayer.pause() : musicController.jamendoPlayer.play()
        case .youtube:
            isPlaying ? musicController.youtubeManager.pause() : musicController.youtubeManager.play()
        case .appleMusic:
            Task {
                if isPlaying {
                    try? await ApplicationMusicPlayer.shared.pause()
                } else {
                    try? await ApplicationMusicPlayer.shared.play()
                }
            }
        }
    }

    private func skipNext() {
        switch musicController.playbackSource {
        case .jamendo:    musicController.jamendoPlayer.skipNext()
        case .youtube:    musicController.youtubeManager.skipNext()
        case .appleMusic: Task { await musicController.skipToNext() }
        }
    }

    private func skipPrevious() {
        switch musicController.playbackSource {
        case .jamendo:    musicController.jamendoPlayer.skipPrevious()
        case .youtube:    musicController.youtubeManager.skipPrevious()
        case .appleMusic: Task { await musicController.skipToPrevious() }
        }
    }
}
