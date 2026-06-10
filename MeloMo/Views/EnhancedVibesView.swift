import SwiftUI

struct EnhancedVibesView: View {
    @EnvironmentObject private var musicController: MusicController
    @State private var selectedCategory: MoodCategory? = nil
    
    let onMoodColorChange: (Color, Color) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Warm Music Design
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FIND YOUR VIBE")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(WarmMusicColors.gold)
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Text("Pick a mood, instant playlist")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(WarmMusicColors.cream.opacity(0.7))
                        
                        // Magic Mood Button
                        Button(action: {
                            Task {
                                Haptics.successPattern()
                                await musicController.generateMagicMood()
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .bold))
                                Text("MAGIC MOOD")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(1)
                                Spacer()
                                Text("DETECT BIOMETRICS")
                                    .font(.system(size: 10, weight: .semibold))
                                    .opacity(0.7)
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [WarmMusicColors.gold.opacity(0.2), Color.white.opacity(0.05)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(WarmMusicColors.gold.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    categoryPills
                    
                    if !musicController.trendingVibes.isEmpty {
                        trendingVibesSection
                    }
                    
                    moodGrid
                }
                .padding(.vertical)
            }
            .background(WarmMusicColors.warmBlack.ignoresSafeArea())
            .onAppear {
                Task { await musicController.fetchTrendingVibes() }
            }
        }
    }
    
    private var trendingVibesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRENDING VIBES")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(WarmMusicColors.gold.opacity(0.8))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<musicController.trendingVibes.count, id: \.self) { index in
                        let vibe = musicController.trendingVibes[index]
                        Button(action: {
                            if let mood = enhancedMoods.first(where: { $0.title == vibe["mood"] }) {
                                Task { await musicController.generate(for: mood) }
                            }
                        }) {
                            HStack {
                                Text(vibe["emoji"] ?? "🎵")
                                Text(vibe["mood"]?.uppercased() ?? "UNKNOWN")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" chip
                CategoryTab(title: "ALL", isSelected: selectedCategory == nil) { selectedCategory = nil }
                
                ForEach(MoodCategory.allCases.filter { $0 != .general }) { category in
                    CategoryTab(title: category.rawValue.uppercased(), isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var moodGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(filteredMoods) { mood in
                MoodCard(mood: mood, isFavorite: musicController.isFavorite(mood)) {
                    Task { await musicController.generate(for: mood) }
                } onFavorite: {
                    musicController.toggleFavorite(mood)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var filteredMoods: [EnhancedMood] {
        if let selectedCategory = selectedCategory {
            return musicController.getMoodsByCategory(selectedCategory)
        } else {
            return enhancedMoods
        }
    }
}


// MARK: - Enhanced Mood Card (Warm Music Version)
struct EnhancedMoodCard: View {
    let mood: EnhancedMood
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            Haptics.moodSelected()
            onTap()
        }) {
            ZStack(alignment: .bottomLeading) {
                // Warm gradient background per mood
                LinearGradient(
                    colors: [
                        mood.backgroundColor.primary.opacity(0.9),
                        mood.backgroundColor.primary.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Sound wave visualization (8-bar equalizer)
                VStack(alignment: .center) {
                    Spacer()
                    
                    HStack(spacing: 3) {
                        ForEach(0..<8, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 3, height: CGFloat([20, 40, 60, 80, 40, 70, 30, 50][index]))
                        }
                    }
                    .frame(height: 80)
                    
                    Spacer()
                }
                .padding(24)
                
                // Mood label (bottom left) - all-caps
                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(mood.musicDescription)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(16)
            }
            .cornerRadius(20)
            .frame(height: 240)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? WarmMusicColors.gold : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .shadow(
                color: isSelected ? mood.backgroundColor.primary.opacity(0.6) : Color.black.opacity(0.3),
                radius: isSelected ? 16 : 8,
                x: 0,
                y: isSelected ? 8 : 4
            )
            .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.95 : 1.0))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Category Tab (Warm Music Version)
struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.3)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    WarmMusicColors.gold :
                    Color.white.opacity(0.1)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Category Filter Chip (Warm Music Version)
struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? WarmMusicColors.gold : Color.white.opacity(0.1)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vibe Card Share Sheet
struct VibeCardShareSheet: View {
    let mood: EnhancedMood
    let topTracks: [MusicTrack]
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Share card
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Share Your Vibe")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                // Vibe card content
                VStack(spacing: 16) {
                    // Mood info
                    HStack(spacing: 16) {
                        Text(mood.emoji)
                            .font(.system(size: 40))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mood.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(mood.musicDescription)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    // Top tracks
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Tracks")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(topTracks.prefix(3), id: \.id) { track in
                            HStack {
                                Text("\(topTracks.firstIndex(where: { $0.id == track.id })! + 1)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(.black)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    mood.backgroundColor.primary.opacity(1),
                                    mood.backgroundColor.secondary.opacity(1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(mood.accentColor.primary.opacity(1), lineWidth: 1)
                        )
                )
                
                // Share button (Warm Music Style)
                Button(action: {
                    shareVibeCard()
                }) {
                    Text("EXPORT PLAYLIST")
                        .font(.system(size: 14, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [WarmMusicColors.gold, WarmMusicColors.copper],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: WarmMusicColors.gold.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                mood.backgroundColor.primary.opacity(0.4),
                                mood.backgroundColor.secondary.opacity(0.3),
                                Color(red: 0.05, green: 0.1, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(mood.accentColor.primary.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(40)
        }
    }
    
    private func shareVibeCard() {
        Haptics.successPattern()
        
        // Create the vibe card as an image
        let vibeCardView = createShareableVibeCard()
        let renderer = ImageRenderer(content: vibeCardView)
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            let activityController = UIActivityViewController(
                activityItems: [image],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityController, animated: true)
            }
        }
    }
    
    private func createShareableVibeCard() -> some View {
        VStack(spacing: 16) {
            // Mood info
            HStack(spacing: 16) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(mood.musicDescription)
                        .font(.caption)
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            
            // Top tracks
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Tracks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(topTracks.prefix(3), id: \.id) { track in
                    HStack {
                        Text("\(topTracks.firstIndex(where: { $0.id == track.id })! + 1)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // MeloMo branding
            Text("Generated By: MeloMo - Find Your Vibe! 🎶")
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            mood.backgroundColor.primary.opacity(1),
                            mood.backgroundColor.secondary.opacity(1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(mood.accentColor.primary.opacity(1), lineWidth: 1)
                )
        )
        .frame(width: 320, height: 400)
    }
}

#Preview {
    EnhancedVibesView(onMoodColorChange: { _, _ in })
        .environmentObject(MusicController())
        .preferredColorScheme(.dark)
}



