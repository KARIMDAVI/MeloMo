import SwiftUI

struct MoodCard: View {
    let mood: Mood
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onShare: () -> Void
    
    // Resolve mood image consistently with other cards
    private var moodImageName: String {
        switch mood.title.lowercased() {
        case "happy": return "happy"
        case "chill": return "Chill"
        case "hype": return "Hype"
        case "heartbreak": return "heartbreak"
        case "moody": return "Moody"
        case "sunny": return "sunny"
        case "focus": return "Focus"
        case "run": return "Run"
        case "throwback": return "Throwback"
        case "magical": return "Magical"
        case "adventure": return "Adventure"
        case "night": return "Night"
        case "dramatic": return "Dramatic"
        case "electric": return "lightning"
        case "party": return "Party"
        case "nature": return "Nature"
        case "sunrise": return "sunrise"
        case "cozy": return "Cozy"
        case "romantic": return "Romantic"
        case "melancholy": return "Melancholy"
        case "hopeful": return "Hopeful"
        case "study": return "Study"
        case "work": return "Work"
        case "determined": return "Determined"
        case "social": return "Social"
        case "rock": return "Rock"
        case "piano": return "Piano"
        case "jazz": return "Jazz"
        case "vocals": return "Vocal"
        case "world": return "World"
        default:
            return mood.imageName.isEmpty ? "happy" : mood.imageName
        }
    }
    
    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    // Mood image
                    Image(moodImageName)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Top-right controls
                    HStack(spacing: 8) {
                        // Share
                        Button {
                            Haptics.tap()
                            onShare()
                        } label: {
                            Image("Share")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Favorite
                        Button {
                            Haptics.light()
                            onFavorite()
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(isFavorite ? .red : .white)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(8)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(mood.emoji)
                            .font(.system(size: 16))
                        
                        Text(mood.title)
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Play indicator
                        Image("Play")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.accentColor)
                            .opacity(0.9)
                    }
                    
                    if !mood.description.isEmpty {
                        Text(mood.description)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MoodCard(
        mood: Mood(
            emoji: "😀",
            imageName: "happy",
            title: "Happy",
            description: "Feeling joyful and upbeat",
            seeds: ["feel good", "pop uplifting", "good vibes"],
            energy: 0.9,
            category: .energetic,
            popularity: 5
        ),
        isFavorite: true,
        onTap: {},
        onFavorite: {},
        onShare: {}
    )
    .padding()
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.1),
                Color(red: 0.1, green: 0.1, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
