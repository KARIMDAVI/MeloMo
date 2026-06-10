// LibraryView.swift — Saved and exported playlists from SwiftData.
// @Query handles real-time updates automatically — no manual refresh needed.
import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \SavedPlaylist.createdAt, order: .reverse) private var playlists: [SavedPlaylist]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if playlists.isEmpty {
                    emptyState
                } else {
                    playlistGrid
                }
            }
            .navigationTitle("Library")
            .background(ThemeColors.background)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text.fa(Icons.library, size: 48)
                .foregroundColor(ThemeColors.textSecondary)
            Text("No Saved Playlists")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            Text("Your saved playlists will appear here.")
                .font(.subheadline)
                .foregroundColor(ThemeColors.textSecondary)
        }
        .padding(.top, 80)
    }
    
    private var playlistGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(playlists) { playlist in
                PlaylistCard(playlist: playlist)
            }
        }
        .padding()
    }
}

struct PlaylistCard: View {
    let playlist: SavedPlaylist
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                Text("\(playlist.trackCount) songs")
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.textSecondary)
            }
            Spacer()
            Text.fa(Icons.chevronRight)
                .foregroundColor(ThemeColors.textSecondary)
        }
        .padding()
        .liquidGlass()
    }
}

