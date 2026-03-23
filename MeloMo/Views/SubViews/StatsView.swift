// StatsView.swift — Real stats from MusicController + StreakManager.
// No fake numbers — if there's nothing to show yet, we say so honestly.
import SwiftUI
import FontAwesome

struct StatsView: View {
    @EnvironmentObject private var musicController: MusicController
    // Singleton observed directly — @StateObject would create a new instance
    @ObservedObject private var streak = StreakManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if streak.currentStreak > 0 {
                        StreakBannerView(streak: streak.currentStreak)
                            .padding(.horizontal, 16)
                    }

                    statsGrid
                        .padding(.horizontal, 16)

                    if !musicController.recentMoods.isEmpty {
                        recentMoodsSection
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(red: 0.04, green: 0.04, blue: 0.08))
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStatCard(icon: Icons.vibes,   label: "Playlists",
                         value: "\(musicController.statistics.totalPlaylistsGenerated)")
            MiniStatCard(icon: Icons.heart,   label: "Fav Mood",
                         value: musicController.statistics.favoriteMood?.title ?? "—")
            MiniStatCard(icon: Icons.fire,    label: "Streak",
                         value: streak.currentStreak > 0 ? "\(streak.currentStreak)d" : "—")
            MiniStatCard(icon: Icons.trophy,  label: "Best",
                         value: streak.longestStreak > 0 ? "\(streak.longestStreak)d" : "—")
        }
    }

    private var recentMoodsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Moods")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(musicController.recentMoods.prefix(10)) { mood in
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title2)
                            Text(mood.title)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        .frame(width: 62, height: 70)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Mini Stat Card

private struct MiniStatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(Font.fontAwesome(ofSize: 22, style: .solid))
                .foregroundColor(.yellow)
            Text(value)
                .font(.title3).fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
