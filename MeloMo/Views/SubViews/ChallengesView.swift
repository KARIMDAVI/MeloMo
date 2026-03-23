// ChallengesView.swift — Data-driven music challenges with real Challenge model.
// Static catalog for now — backend-driven challenges are a v3 feature.
// Accessible from the Profile tab so it doesn't clutter the main 4-tab nav.
import SwiftUI
import FontAwesome

// MARK: - Challenge Model

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let difficulty: Difficulty

    enum Difficulty: String {
        case easy   = "Easy"
        case medium = "Medium"
        case hard   = "Hard"

        var color: Color {
            switch self {
            case .easy:   return .green
            case .medium: return .yellow
            case .hard:   return .red
            }
        }
    }
}

// MARK: - Challenge Catalog

// Static for v1 — swap this array with an API call when the backend supports challenges
private let challengeCatalog: [Challenge] = [
    Challenge(title: "Genre Master",
              description: "Generate playlists in 5 different mood categories",
              icon: Icons.vibes, difficulty: .easy),
    Challenge(title: "Streak Starter",
              description: "Pick your daily mood 3 days in a row",
              icon: Icons.fire, difficulty: .easy),
    Challenge(title: "Music Explorer",
              description: "Try all 3 sources: Jamendo, YouTube, and Apple Music",
              icon: Icons.trophy, difficulty: .medium),
    Challenge(title: "Vibe Curator",
              description: "Save 5 playlists to your library",
              icon: Icons.library, difficulty: .medium),
    Challenge(title: "Share the Vibe",
              description: "Export a playlist to Spotify or Apple Music",
              icon: Icons.export, difficulty: .hard),
]

// MARK: - View

struct ChallengesView: View {
    @ObservedObject private var streak = StreakManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if streak.currentStreak > 0 {
                        StreakBannerView(streak: streak.currentStreak)
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(challengeCatalog) { challenge in
                            ChallengeRow(challenge: challenge)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(red: 0.04, green: 0.04, blue: 0.08))
        }
    }
}

// MARK: - Challenge Row

struct ChallengeRow: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 14) {
            Text(challenge.icon)
                .font(Font.fontAwesome(ofSize: 20, style: .solid))
                .foregroundColor(.yellow)
                .frame(width: 44, height: 44)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(challenge.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(challenge.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(challenge.difficulty.rawValue)
                .font(.caption2).fontWeight(.medium)
                .foregroundColor(challenge.difficulty.color)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(challenge.difficulty.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
