// MeloMo/Views/Tabs/VibesView.swift
import SwiftUI

struct VibesView: View {
    @EnvironmentObject private var musicController: MusicController
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Mood selection for all users
                VStack(spacing: 16) {
                    Text("Choose Your Vibe")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Mood grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(Array(enhancedMoods.prefix(6)), id: \.id) { mood in
                            MoodCard(mood: mood, isFavorite: false, onTap: {
                                Task {
                                    await musicController.generate(for: mood)
                                }
                            }, onFavorite: {
                                musicController.toggleFavorite(mood)
                            }, onShare: {
                                // Handle share
                            })
                        }
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
