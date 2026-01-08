import Foundation

/// Enhanced mood collection with descriptions and categories
let allMoods: [Mood] = [
    // Energetic Moods
    Mood(
        emoji: "😀",
        imageName: "happy",
        title: "Happy",
        description: "Feeling joyful and upbeat",
        seeds: ["feel good", "pop uplifting", "good vibes", "summer pop", "dance pop"],
        energy: 0.9,
        category: .energetic,
        popularity: 5
    ),
    
    Mood(
        emoji: "🔥",
        imageName: "Hype",
        title: "Hype",
        description: "Ready to get pumped up",
        seeds: ["electro house", "trap", "workout", "edm", "bass", "dubstep"],
        energy: 1.0,
        category: .energetic,
        popularity: 4
    ),
    
    Mood(
        emoji: "🏃",
        imageName: "Run",
        title: "Run",
        description: "Perfect for workouts and exercise",
        seeds: ["running", "pop workout", "dance pop", "electronic", "motivational"],
        energy: 0.8,
        category: .energetic,
        popularity: 3
    ),
    
    // Relaxed Moods
    Mood(
        emoji: "😌",
        imageName: "Chill",
        title: "Chill",
        description: "Time to relax and unwind",
        seeds: ["lofi", "chillhop", "ambient pop", "downtempo", "chill beats"],
        energy: 0.3,
        category: .relaxed,
        popularity: 5
    ),
    
    Mood(
        emoji: "☀️",
        imageName: "sunny",
        title: "Sunny",
        description: "Bright and cheerful vibes",
        seeds: ["tropical house", "sunny pop", "bossa nova", "beach vibes", "summer"],
        energy: 0.6,
        category: .relaxed,
        popularity: 4
    ),
    
    // Emotional Moods
    Mood(
        emoji: "💔",
        imageName: "heartbreak",
        title: "Heartbreak",
        description: "Processing emotions and healing",
        seeds: ["sad indie", "piano ballad", "dreampop", "emotional", "healing"],
        energy: 0.2,
        category: .emotional,
        popularity: 3
    ),
    
    Mood(
        emoji: "🌧️",
        imageName: "Moody",
        title: "Moody",
        description: "Deep and introspective",
        seeds: ["alt r&b", "dark pop", "trip hop", "atmospheric", "moody"],
        energy: 0.4,
        category: .emotional,
        popularity: 2
    ),
    
    // Focused Moods
    Mood(
        emoji: "🧠",
        imageName: "Focus",
        title: "Focus",
        description: "Concentration and productivity",
        seeds: ["focus", "instrumental", "classical minimal", "study", "productivity"],
        energy: 0.2,
        category: .focused,
        popularity: 4
    ),
    
    // Social Moods
    Mood(
        emoji: "🕺",
        imageName: "Throwback",
        title: "Throwback",
        description: "Nostalgic and fun memories",
        seeds: ["80s pop", "90s r&b", "classic rock", "retro", "nostalgic"],
        energy: 0.7,
        category: .social,
        popularity: 4
    ),
    
    // Additional Enhanced Moods
    Mood(
        emoji: "✨",
        imageName: "Magical",
        title: "Magical",
        description: "Mystical and enchanting vibes",
        seeds: ["ethereal", "ambient", "cinematic", "magical", "dreamy"],
        energy: 0.5,
        category: .relaxed,
        popularity: 3
    ),
    
    Mood(
        emoji: "🚀",
        imageName: "Adventure",
        title: "Adventure",
        description: "Ready for exploration and discovery",
        seeds: ["epic", "soundtrack", "adventure", "cinematic", "inspiring"],
        energy: 0.8,
        category: .energetic,
        popularity: 3
    ),
    
    Mood(
        emoji: "🌙",
        imageName: "Night",
        title: "Night",
        description: "Perfect for evening vibes",
        seeds: ["night", "evening", "smooth", "jazz", "ambient"],
        energy: 0.4,
        category: .relaxed,
        popularity: 3
    ),
    
    Mood(
        emoji: "🎭",
        imageName: "Dramatic",
        title: "Dramatic",
        description: "Intense and theatrical emotions",
        seeds: ["dramatic", "orchestral", "epic", "cinematic", "intense"],
        energy: 0.7,
        category: .emotional,
        popularity: 2
    )
]

/// Get moods by category
func getMoodsByCategory(_ category: MoodCategory) -> [Mood] {
    return allMoods.filter { $0.category == category }
}

/// Get popular moods (popularity >= 4)
func getPopularMoods() -> [Mood] {
    return allMoods.filter { $0.popularity >= 4 }
}

/// Get moods by energy level
func getMoodsByEnergy(min: Double, max: Double) -> [Mood] {
    return allMoods.filter { $0.energy >= min && $0.energy <= max }
}

/// Get random mood for discovery
func getRandomMood() -> Mood? {
    return allMoods.randomElement()
}
