// MeloMo/Views/Tabs/ChallengesView.swift
import SwiftUI

struct ChallengesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Challenges content for signed-in users
                VStack(spacing: 16) {
                    Text("Music Challenges")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Test your music knowledge with trivia challenges")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Placeholder for actual challenges
                    VStack(spacing: 12) {
                        ChallengeCard(title: "Genre Master", description: "Identify 10 different music genres", difficulty: "Easy")
                        ChallengeCard(title: "Artist Expert", description: "Name the artist from song snippets", difficulty: "Medium")
                        ChallengeCard(title: "Decade Detective", description: "Guess the decade of popular songs", difficulty: "Hard")
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Current Vibe Card
    private var currentVibeCard: some View {
        HStack(spacing: 16) {
            // Magical stars
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Vibe")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Magical")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Music note
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
