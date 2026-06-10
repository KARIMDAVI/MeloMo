// MeloMo/Views/Tabs/StatsView.swift
import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var musicController: MusicController
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    StatCard(title: "Total Playlists", value: "\(musicController.statistics.totalPlaylistsGenerated)", icon: Icons.vibes)
                    StatCard(title: "Favorite Mood", value: musicController.statistics.favoriteMood?.title ?? "None", icon: Icons.heart)
                    StatCard(title: "Listening Time", value: "2h 30m", icon: .clock)
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(ThemeColors.background)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: FontAwesome.Icon
    
    var body: some View {
        HStack {
            Text.fa(icon, size: 24)
                .foregroundColor(ThemeColors.primaryAccent)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                Text(value)
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(ThemeColors.text)
            }
            Spacer()
        }
        .padding()
        .liquidGlass()
    }
}

