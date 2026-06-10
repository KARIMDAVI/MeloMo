// ExportSheetView.swift — Bottom sheet for cloning playlist to streaming apps.
// ExportManager handles the actual API calls — this view is pure presentation.
import SwiftUI
import FontAwesome

struct ExportSheetView: View {
    @EnvironmentObject private var musicController: MusicController
    @StateObject private var exportManager = ExportManager()
    @Environment(\.dismiss) private var dismiss
    @State private var exportResult: String? = nil

    let playlistName: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Clone to Your App")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.top, 24)

                Text("Your playlist will appear in the app you choose.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    ExportDestinationRow(
                        icon: Icons.spotify, iconStyle: .brands,
                        name: "Spotify", color: Color(red: 0.11, green: 0.73, blue: 0.33)
                    ) { await export(to: "spotify") }

                    ExportDestinationRow(
                        icon: Icons.apple, iconStyle: .brands,
                        name: "Apple Music", color: .pink
                    ) { await exportAppleMusic() }

                    ExportDestinationRow(
                        icon: Icons.youtube, iconStyle: .brands,
                        name: "YouTube Music", color: .red
                    ) { await export(to: "youtube_music") }
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)

                if let result = exportResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.12))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
        }
    }

    private func export(to destination: String) async {
        guard let tracks = musicController.backendResponse?.tracks, !tracks.isEmpty else {
            exportResult = "No tracks to export — generate a playlist first"
            return
        }
        // OAuth tokens are placeholders — full OAuth flow is a v2 feature
        do {
            if destination == "spotify" {
                try await exportManager.exportToSpotify(
                    tracks: tracks, playlistName: playlistName,
                    accessToken: "YOUR_SPOTIFY_TOKEN", userId: "YOUR_SPOTIFY_USER_ID"
                )
            } else {
                try await exportManager.exportToYouTubeMusic(
                    tracks: tracks, playlistName: playlistName,
                    accessToken: "YOUR_YOUTUBE_TOKEN"
                )
            }
            exportResult = exportManager.lastResult?.summary ?? "Export complete"
        } catch {
            exportResult = "Export failed: \(error.localizedDescription)"
        }
    }

    private func exportAppleMusic() async {
        guard let tracks = musicController.backendResponse?.tracks, !tracks.isEmpty else {
            exportResult = "No tracks to export — generate a playlist first"
            return
        }
        do {
            try await exportManager.exportToAppleMusic(tracks: tracks, playlistName: playlistName)
            exportResult = exportManager.lastResult?.summary ?? "Added to Apple Music"
        } catch {
            exportResult = "Apple Music: ensure you're signed in to the Music app, then try again."
        }
    }
}

// MARK: - Export Destination Row

struct ExportDestinationRow: View {
    let icon: String
    let iconStyle: FontAwesomeStyle
    let name: String
    let color: Color
    let action: () async -> Void

    var body: some View {
        Button(action: { Task { await action() } }) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(Font.fontAwesome(ofSize: 22, style: iconStyle))
                    .foregroundColor(color)
                    .frame(width: 36)
                Text(name)
                    .font(.body).fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
