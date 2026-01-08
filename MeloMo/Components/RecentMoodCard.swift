import SwiftUI

struct RecentMoodCard: View {
    let mood: Mood
    let onTap: () -> Void
    
    // Helper to resolve mood image consistently with your assets
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
            // Fallback to provided imageName if present; otherwise a generic
            return mood.imageName.isEmpty ? "happy" : mood.imageName
        }
    }
    
    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(moodImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mood.title)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.primary)
                    
                    if !mood.description.isEmpty {
                        Text(mood.description)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image("Play")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RecentMoodCard(
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
        onTap: {}
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
