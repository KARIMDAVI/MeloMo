import SwiftUI

// MARK: - Warm Mood Card Component (Magnetto Style)
struct WarmMoodCard: View {
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
                // Gradient background (warm tone per mood)
                LinearGradient(
                    colors: [
                        mood.backgroundColor.primary.opacity(0.9),
                        mood.backgroundColor.primary.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Sound wave visualization
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
                
                // Mood label (bottom left)
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

// MARK: - Warm Primary Button (Copper/Gold)
struct WarmPrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let icon: String?
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
                
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
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
        .buttonStyle(PlainButtonStyle())
        .opacity(isLoading ? 0.8 : 1.0)
    }
}

// MARK: - Vinyl Record Card (Now Playing)
struct VinylRecordCard: View {
    let mood: EnhancedMood
    let isSpinning: Bool = false
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Vinyl record background
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)),
                            Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
            
            // Vinyl grooves (concentric circles)
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .stroke(
                        Color.black.opacity(Double(index) * 0.04),
                        lineWidth: 1
                    )
                    .frame(width: 200 - CGFloat(index * 14))
            }
            
            // Center label (golden)
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            WarmMusicColors.gold,
                            WarmMusicColors.copper
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
            
            // Center label text
            Text(mood.emoji)
                .font(.system(size: 32))
        }
        .frame(width: 280, height: 280)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            if isSpinning {
                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
        .shadow(color: mood.backgroundColor.primary.opacity(0.4), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Now Playing Card (Prominent)
struct WarmNowPlayingCard: View {
    let track: String
    let artist: String
    let mood: EnhancedMood
    let isPlaying: Bool
    let onPlayTap: () -> Void
    let onExport: () -> Void
    
    @State private var progress: Double = 0.35
    
    var body: some View {
        VStack(spacing: 24) {
            // Vinyl record
            VinylRecordCard(mood: mood, isSpinning: isPlaying)
            
            // Track info
            VStack(spacing: 8) {
                Text(track)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .lineLimit(2)
                
                Text(artist)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(WarmMusicColors.gold)
            }
            
            // Progress bar (golden)
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [WarmMusicColors.gold, WarmMusicColors.copper],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                        
                        // Scrubber handle
                        Circle()
                            .fill(WarmMusicColors.gold)
                            .frame(width: 12, height: 12)
                            .offset(x: (geo.size.width * progress) - 6)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text("1:20")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(WarmMusicColors.gold)
                    
                    Spacer()
                    
                    Text("3:45")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(WarmMusicColors.gold)
                }
            }
            
            // Playback controls
            HStack(spacing: 24) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(WarmMusicColors.gold)
                        .frame(width: 44, height: 44)
                }
                
                Button(action: onPlayTap) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(WarmMusicColors.gold)
                        .clipShape(Circle())
                        .shadow(color: WarmMusicColors.gold.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(WarmMusicColors.gold)
                        .frame(width: 44, height: 44)
                }
            }
            
            Spacer()
            
            // Export button
            WarmPrimaryButton(title: "Export to Spotify", action: onExport, isLoading: false, icon: "square.and.arrow.up")
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    WarmMusicColors.warmBlack,
                    WarmMusicColors.vinylBlack.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(WarmMusicColors.gold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: mood.backgroundColor.primary.opacity(0.4), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Category Filter Chip (Warm Style)
struct WarmCategoryChip: View {
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
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    AnyShapeStyle(Color(WarmMusicColors.gold)) :
                    AnyShapeStyle(Color.white.opacity(0.1))
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        WarmMusicColors.warmBlack.ignoresSafeArea()
        
        VStack(spacing: 20) {
            WarmMoodCard(
                mood: EnhancedMood(
                    id: "1",
                    title: "Energetic",
                    emoji: "🔥",
                    musicDescription: "High-energy vibes",
                    energy: 0.9,
                    seeds: ["dance"],
                    backgroundColor: (
                        primary: WarmMusicColors.burntOrange,
                        secondary: WarmMusicColors.gold
                    ),
                    accentColor: (
                        primary: WarmMusicColors.gold,
                        secondary: WarmMusicColors.copper
                    )
                ),
                isSelected: false,
                onTap: {}
            )
            
            WarmPrimaryButton(
                title: "Export Playlist",
                action: {},
                isLoading: false,
                icon: "square.and.arrow.up"
            )
            
            Spacer()
        }
        .padding(16)
    }
}
