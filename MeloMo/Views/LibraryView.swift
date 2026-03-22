// LibraryView.swift — Saved and exported playlists from SwiftData.
// @Query handles real-time updates automatically — no manual refresh needed.
import SwiftUI
import SwiftData
import FontAwesome

struct LibraryView: View {
    @Query(sort: \SavedPlaylist.createdAt, order: .reverse) private var playlists: [SavedPlaylist]
    @EnvironmentObject private var musicController: MusicController

    var body: some View {
        NavigationStack {
            ScrollView {
                if playlists.isEmpty {
                    VStack(spacing: 16) {
                        Text(Icons.library)
                            .font(Font.fontAwesome(ofSize: 48, style: .solid))
                            .foregroundColor(.gray)
                        Text("No saved playlists yet")
                            .foregroundColor(.gray)
                        Text("Generate a playlist and save it to your library")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(playlists) { playlist in
                            PlaylistCard(playlist: playlist)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(red: 0.04, green: 0.04, blue: 0.08))
        }
    }
}

// MARK: - Playlist Card

struct PlaylistCard: View {
    let playlist: SavedPlaylist

    var body: some View {
        HStack(spacing: 14) {
            Text(playlist.moodEmoji)
                .font(.title)
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("\(playlist.trackCount) songs · \(playlist.moodTitle)")
                    .font(.caption)
                    .foregroundColor(.gray)

                // Export destination badges
                if !playlist.exportedTo.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(playlist.exportedTo, id: \.self) { dest in
                            Text(dest == "spotify" ? Icons.spotify
                                 : dest == "apple_music" ? Icons.apple
                                 : Icons.youtube)
                                .font(Font.fontAwesome(ofSize: 10, style: .brands))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
