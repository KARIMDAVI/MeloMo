import Foundation
import SwiftUI

// MARK: - Enhanced Mood Structure with Colors
struct EnhancedMood: Identifiable, Hashable, Codable {
    let id = UUID()
    let emoji: String
    let imageName: String
    let title: String
    let description: String
    let seeds: [String]
    let energy: Double
    let category: MoodCategory
    let popularity: Int
    let backgroundColor: MoodColor
    let accentColor: MoodColor
    let musicDescription: String
    
    init(emoji: String, imageName: String = "", title: String, description: String = "", seeds: [String], energy: Double, category: MoodCategory = .general, popularity: Int = 1, backgroundColor: MoodColor, accentColor: MoodColor, musicDescription: String) {
        self.emoji = emoji
        self.imageName = imageName
        self.title = title
        self.description = description
        self.seeds = seeds
        self.energy = energy
        self.category = category
        self.popularity = popularity
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
        self.musicDescription = musicDescription
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case emoji, imageName, title, description, seeds, energy, category, popularity, backgroundColor, accentColor, musicDescription
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        emoji = try container.decode(String.self, forKey: .emoji)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? ""
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        seeds = try container.decode([String].self, forKey: .seeds)
        energy = try container.decode(Double.self, forKey: .energy)
        category = try container.decode(MoodCategory.self, forKey: .category)
        popularity = try container.decode(Int.self, forKey: .popularity)
        backgroundColor = try container.decode(MoodColor.self, forKey: .backgroundColor)
        accentColor = try container.decode(MoodColor.self, forKey: .accentColor)
        musicDescription = try container.decode(String.self, forKey: .musicDescription)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(seeds, forKey: .seeds)
        try container.encode(energy, forKey: .energy)
        try container.encode(category, forKey: .category)
        try container.encode(popularity, forKey: .popularity)
        try container.encode(backgroundColor, forKey: .backgroundColor)
        try container.encode(accentColor, forKey: .accentColor)
        try container.encode(musicDescription, forKey: .musicDescription)
    }
}

// MARK: - Mood Color System
struct MoodColor: Codable, Hashable {
    let primary: Color
    let secondary: Color
    let accent: Color
    
    init(primary: Color, secondary: Color, accent: Color) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case primaryRed, primaryGreen, primaryBlue, primaryAlpha
        case secondaryRed, secondaryGreen, secondaryBlue, secondaryAlpha
        case accentRed, accentGreen, accentBlue, accentAlpha
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let primaryRed = try container.decode(Double.self, forKey: .primaryRed)
        let primaryGreen = try container.decode(Double.self, forKey: .primaryGreen)
        let primaryBlue = try container.decode(Double.self, forKey: .primaryBlue)
        let primaryAlpha = try container.decode(Double.self, forKey: .primaryAlpha)
        
        let secondaryRed = try container.decode(Double.self, forKey: .secondaryRed)
        let secondaryGreen = try container.decode(Double.self, forKey: .secondaryGreen)
        let secondaryBlue = try container.decode(Double.self, forKey: .secondaryBlue)
        let secondaryAlpha = try container.decode(Double.self, forKey: .secondaryAlpha)
        
        let accentRed = try container.decode(Double.self, forKey: .accentRed)
        let accentGreen = try container.decode(Double.self, forKey: .accentGreen)
        let accentBlue = try container.decode(Double.self, forKey: .accentBlue)
        let accentAlpha = try container.decode(Double.self, forKey: .accentAlpha)
        
        self.primary = Color(red: primaryRed, green: primaryGreen, blue: primaryBlue, opacity: primaryAlpha)
        self.secondary = Color(red: secondaryRed, green: secondaryGreen, blue: secondaryBlue, opacity: secondaryAlpha)
        self.accent = Color(red: accentRed, green: accentGreen, blue: accentBlue, opacity: accentAlpha)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let primaryComponents = UIColor(self.primary).cgColor.components ?? [0, 0, 0, 1]
        try container.encode(primaryComponents[0], forKey: .primaryRed)
        try container.encode(primaryComponents[1], forKey: .primaryGreen)
        try container.encode(primaryComponents[2], forKey: .primaryBlue)
        try container.encode(primaryComponents[3], forKey: .primaryAlpha)
        
        let secondaryComponents = UIColor(self.secondary).cgColor.components ?? [0, 0, 0, 1]
        try container.encode(secondaryComponents[0], forKey: .secondaryRed)
        try container.encode(secondaryComponents[1], forKey: .secondaryGreen)
        try container.encode(secondaryComponents[2], forKey: .secondaryBlue)
        try container.encode(secondaryComponents[3], forKey: .secondaryAlpha)
        
        let accentComponents = UIColor(self.accent).cgColor.components ?? [0, 0, 0, 1]
        try container.encode(accentComponents[0], forKey: .accentRed)
        try container.encode(accentComponents[1], forKey: .accentGreen)
        try container.encode(accentComponents[2], forKey: .accentBlue)
        try container.encode(accentComponents[3], forKey: .accentAlpha)
    }
}

// MARK: - Comprehensive Mood Collection
let enhancedMoods: [EnhancedMood] = [
    // POSITIVE MOODS - High Energy
    EnhancedMood(
        emoji: "😀",
        imageName: "happy",
        title: "Happy",
        description: "Feeling joyful and upbeat",
        seeds: ["feel good", "pop uplifting", "good vibes", "summer pop", "dance pop"],
        energy: 0.9,
        category: .energetic,
        popularity: 5,
        backgroundColor: MoodColor(primary: .yellow, secondary: .orange, accent: .white),
        accentColor: MoodColor(primary: .orange, secondary: .yellow, accent: .white),
        musicDescription: "Upbeat pop and dance tracks that make you want to move"
    ),
    
    EnhancedMood(
        emoji: "😊",
        imageName: "happy",
        title: "Cheerful",
        description: "Bright and optimistic",
        seeds: ["cheerful", "bright pop", "optimistic", "uplifting", "positive"],
        energy: 0.8,
        category: .energetic,
        popularity: 4,
        backgroundColor: MoodColor(primary: .cyan, secondary: .blue, accent: .white),
        accentColor: MoodColor(primary: .blue, secondary: .cyan, accent: .white),
        musicDescription: "Bright, cheerful melodies that lift your spirits"
    ),
    
    EnhancedMood(
        emoji: "🤩",
        imageName: "Hype",
        title: "Enthusiastic",
        description: "Full of excitement and energy",
        seeds: ["enthusiastic", "energetic", "excited", "pumped up", "high energy"],
        energy: 1.0,
        category: .energetic,
        popularity: 4,
        backgroundColor: MoodColor(primary: .red, secondary: .pink, accent: .white),
        accentColor: MoodColor(primary: .pink, secondary: .red, accent: .white),
        musicDescription: "High-energy tracks that fuel your enthusiasm"
    ),
    
    EnhancedMood(
        emoji: "⚡",
        imageName: "Hype",
        title: "Excited",
        description: "Thrilled and energized",
        seeds: ["excited", "thrilling", "energetic", "electric", "adrenaline"],
        energy: 0.95,
        category: .energetic,
        popularity: 4,
        backgroundColor: MoodColor(primary: .purple, secondary: .magenta, accent: .white),
        accentColor: MoodColor(primary: .magenta, secondary: .purple, accent: .white),
        musicDescription: "Electric and thrilling beats that match your excitement"
    ),
    
    // POSITIVE MOODS - Low Energy
    EnhancedMood(
        emoji: "😌",
        imageName: "Chill",
        title: "Relaxed",
        description: "Calm and at ease",
        seeds: ["relaxed", "calm", "peaceful", "chill", "easy going"],
        energy: 0.3,
        category: .chill,
        popularity: 5,
        backgroundColor: MoodColor(primary: .mint, secondary: .teal, accent: .white),
        accentColor: MoodColor(primary: .teal, secondary: .mint, accent: .white),
        musicDescription: "Smooth, calming tracks for ultimate relaxation"
    ),
    
    EnhancedMood(
        emoji: "🧘",
        imageName: "Chill",
        title: "Calm",
        description: "Serene and peaceful",
        seeds: ["calm", "serene", "peaceful", "meditation", "zen"],
        energy: 0.2,
        category: .chill,
        popularity: 4,
        backgroundColor: MoodColor(primary: .indigo, secondary: .blue, accent: .white),
        accentColor: MoodColor(primary: .blue, secondary: .indigo, accent: .white),
        musicDescription: "Gentle, meditative sounds for inner peace"
    ),
    
    EnhancedMood(
        emoji: "😇",
        imageName: "Chill",
        title: "Content",
        description: "Satisfied and fulfilled",
        seeds: ["content", "satisfied", "fulfilled", "grateful", "blessed"],
        energy: 0.4,
        category: .chill,
        popularity: 3,
        backgroundColor: MoodColor(primary: .green, secondary: .mint, accent: .white),
        accentColor: MoodColor(primary: .mint, secondary: .green, accent: .white),
        musicDescription: "Warm, satisfying melodies that bring contentment"
    ),
    
    EnhancedMood(
        emoji: "🕊️",
        imageName: "Chill",
        title: "Peaceful",
        description: "Tranquil and harmonious",
        seeds: ["peaceful", "tranquil", "harmonious", "serene", "quiet"],
        energy: 0.1,
        category: .chill,
        popularity: 3,
        backgroundColor: MoodColor(primary: .lavender, secondary: .purple, accent: .white),
        accentColor: MoodColor(primary: .purple, secondary: .lavender, accent: .white),
        musicDescription: "Soft, harmonious sounds for perfect tranquility"
    ),
    
    // NEGATIVE MOODS - High Energy
    EnhancedMood(
        emoji: "😠",
        imageName: "Dramatic",
        title: "Angry",
        description: "Frustrated and heated",
        seeds: ["angry", "frustrated", "heated", "aggressive", "intense"],
        energy: 0.9,
        category: .melancholy,
        popularity: 3,
        backgroundColor: MoodColor(primary: .red, secondary: .darkRed, accent: .white),
        accentColor: MoodColor(primary: .darkRed, secondary: .red, accent: .white),
        musicDescription: "Intense, powerful tracks to channel your energy"
    ),
    
    EnhancedMood(
        emoji: "😤",
        imageName: "Dramatic",
        title: "Irritable",
        description: "Annoyed and on edge",
        seeds: ["irritable", "annoyed", "frustrated", "tense", "edgy"],
        energy: 0.7,
        category: .melancholy,
        popularity: 2,
        backgroundColor: MoodColor(primary: .orange, secondary: .red, accent: .white),
        accentColor: MoodColor(primary: .red, secondary: .orange, accent: .white),
        musicDescription: "Edgy, intense music to match your mood"
    ),
    
    EnhancedMood(
        emoji: "😡",
        imageName: "Dramatic",
        title: "Stressed",
        description: "Overwhelmed and tense",
        seeds: ["stressed", "overwhelmed", "tense", "pressure", "anxiety"],
        energy: 0.8,
        category: .melancholy,
        popularity: 3,
        backgroundColor: MoodColor(primary: .brown, secondary: .red, accent: .white),
        accentColor: MoodColor(primary: .red, secondary: .brown, accent: .white),
        musicDescription: "Cathartic tracks to help release tension"
    ),
    
    // NEGATIVE MOODS - Low Energy
    EnhancedMood(
        emoji: "😢",
        imageName: "Melancholy",
        title: "Sad",
        description: "Feeling down and blue",
        seeds: ["sad", "blue", "down", "melancholy", "emotional"],
        energy: 0.2,
        category: .melancholy,
        popularity: 4,
        backgroundColor: MoodColor(primary: .blue, secondary: .darkBlue, accent: .white),
        accentColor: MoodColor(primary: .darkBlue, secondary: .blue, accent: .white),
        musicDescription: "Emotional ballads and soulful melodies for healing"
    ),
    
    EnhancedMood(
        emoji: "😔",
        imageName: "Melancholy",
        title: "Depressed",
        description: "Feeling low and hopeless",
        seeds: ["depressed", "low", "hopeless", "empty", "numb"],
        energy: 0.1,
        category: .melancholy,
        popularity: 2,
        backgroundColor: MoodColor(primary: .gray, secondary: .darkGray, accent: .white),
        accentColor: MoodColor(primary: .darkGray, secondary: .gray, accent: .white),
        musicDescription: "Gentle, understanding music for difficult times"
    ),
    
    EnhancedMood(
        emoji: "😰",
        imageName: "Moody",
        title: "Anxious",
        description: "Worried and nervous",
        seeds: ["anxious", "worried", "nervous", "uneasy", "restless"],
        energy: 0.6,
        category: .melancholy,
        popularity: 3,
        backgroundColor: MoodColor(primary: .yellow, secondary: .orange, accent: .white),
        accentColor: MoodColor(primary: .orange, secondary: .yellow, accent: .white),
        musicDescription: "Calming tracks to ease your worries"
    ),
    
    EnhancedMood(
        emoji: "🌧️",
        imageName: "Moody",
        title: "Gloomy",
        description: "Dark and melancholic",
        seeds: ["gloomy", "dark", "melancholic", "somber", "dreary"],
        energy: 0.3,
        category: .melancholy,
        popularity: 2,
        backgroundColor: MoodColor(primary: .darkGray, secondary: .black, accent: .white),
        accentColor: MoodColor(primary: .black, secondary: .darkGray, accent: .white),
        musicDescription: "Atmospheric, introspective music for reflection"
    ),
    
    EnhancedMood(
        emoji: "🎭",
        imageName: "Melancholy",
        title: "Melancholy",
        description: "Thoughtful and wistful",
        seeds: ["melancholy", "wistful", "thoughtful", "nostalgic", "reflective"],
        energy: 0.4,
        category: .melancholy,
        popularity: 3,
        backgroundColor: MoodColor(primary: .purple, secondary: .indigo, accent: .white),
        accentColor: MoodColor(primary: .indigo, secondary: .purple, accent: .white),
        musicDescription: "Poetic, reflective melodies for deep emotions"
    ),
    
    // ROMANTIC MOODS
    EnhancedMood(
        emoji: "💕",
        imageName: "Romantic",
        title: "Romantic",
        description: "Loving and passionate",
        seeds: ["romantic", "love", "passionate", "intimate", "sweet"],
        energy: 0.6,
        category: .romantic,
        popularity: 4,
        backgroundColor: MoodColor(primary: .pink, secondary: .red, accent: .white),
        accentColor: MoodColor(primary: .red, secondary: .pink, accent: .white),
        musicDescription: "Beautiful love songs and romantic melodies"
    ),
    
    EnhancedMood(
        emoji: "💖",
        imageName: "Romantic",
        title: "Loving",
        description: "Full of affection",
        seeds: ["loving", "affectionate", "tender", "caring", "warm"],
        energy: 0.5,
        category: .romantic,
        popularity: 3,
        backgroundColor: MoodColor(primary: .rose, secondary: .pink, accent: .white),
        accentColor: MoodColor(primary: .pink, secondary: .rose, accent: .white),
        musicDescription: "Tender, affectionate songs about love"
    ),
    
    EnhancedMood(
        emoji: "💘",
        imageName: "Romantic",
        title: "Passionate",
        description: "Intense and fiery",
        seeds: ["passionate", "intense", "fiery", "hot", "sultry"],
        energy: 0.8,
        category: .romantic,
        popularity: 3,
        backgroundColor: MoodColor(primary: .red, secondary: .darkRed, accent: .white),
        accentColor: MoodColor(primary: .darkRed, secondary: .red, accent: .white),
        musicDescription: "Sultry, passionate tracks for intense moments"
    ),
    
    // CREATIVE MOODS
    EnhancedMood(
        emoji: "🎨",
        imageName: "Magical",
        title: "Creative",
        description: "Inspired and artistic",
        seeds: ["creative", "artistic", "inspired", "imaginative", "innovative"],
        energy: 0.7,
        category: .magical,
        popularity: 3,
        backgroundColor: MoodColor(primary: .purple, secondary: .magenta, accent: .white),
        accentColor: MoodColor(primary: .magenta, secondary: .purple, accent: .white),
        musicDescription: "Inspiring, creative tracks to fuel your imagination"
    ),
    
    EnhancedMood(
        emoji: "✨",
        imageName: "Magical",
        title: "Inspired",
        description: "Motivated and creative",
        seeds: ["inspired", "motivated", "creative", "uplifting", "encouraging"],
        energy: 0.8,
        category: .magical,
        popularity: 4,
        backgroundColor: MoodColor(primary: .gold, secondary: .yellow, accent: .white),
        accentColor: MoodColor(primary: .yellow, secondary: .gold, accent: .white),
        musicDescription: "Motivational tracks that spark creativity"
    ),
    
    EnhancedMood(
        emoji: "🌟",
        imageName: "Magical",
        title: "Hopeful",
        description: "Optimistic about the future",
        seeds: ["hopeful", "optimistic", "future", "dreams", "aspirations"],
        energy: 0.7,
        category: .magical,
        popularity: 4,
        backgroundColor: MoodColor(primary: .cyan, secondary: .blue, accent: .white),
        accentColor: MoodColor(primary: .blue, secondary: .cyan, accent: .white),
        musicDescription: "Uplifting songs about hope and dreams"
    ),
    
    EnhancedMood(
        emoji: "🎭",
        imageName: "Magical",
        title: "Dramatic",
        description: "Theatrical and intense",
        seeds: ["dramatic", "theatrical", "intense", "powerful", "epic"],
        energy: 0.8,
        category: .magical,
        popularity: 3,
        backgroundColor: MoodColor(primary: .darkRed, secondary: .purple, accent: .white),
        accentColor: MoodColor(primary: .purple, secondary: .darkRed, accent: .white),
        musicDescription: "Epic, theatrical music for dramatic moments"
    ),
    
    // ENERGETIC MOODS
    EnhancedMood(
        emoji: "🔥",
        imageName: "Hype",
        title: "Energetic",
        description: "Full of power and vigor",
        seeds: ["energetic", "powerful", "vigorous", "dynamic", "intense"],
        energy: 0.95,
        category: .energetic,
        popularity: 4,
        backgroundColor: MoodColor(primary: .orange, secondary: .red, accent: .white),
        accentColor: MoodColor(primary: .red, secondary: .orange, accent: .white),
        musicDescription: "High-energy tracks that fuel your power"
    ),
    
    EnhancedMood(
        emoji: "⚡",
        imageName: "Hype",
        title: "Electric",
        description: "Charged and dynamic",
        seeds: ["electric", "charged", "dynamic", "electrifying", "powerful"],
        energy: 1.0,
        category: .energetic,
        popularity: 4,
        backgroundColor: MoodColor(primary: .yellow, secondary: .orange, accent: .white),
        accentColor: MoodColor(primary: .orange, secondary: .yellow, accent: .white),
        musicDescription: "Electrifying beats that charge you up"
    ),
    
    EnhancedMood(
        emoji: "🚀",
        imageName: "Adventure",
        title: "Adventurous",
        description: "Ready for exploration",
        seeds: ["adventurous", "exploration", "journey", "discovery", "bold"],
        energy: 0.9,
        category: .energetic,
        popularity: 3,
        backgroundColor: MoodColor(primary: .blue, secondary: .cyan, accent: .white),
        accentColor: MoodColor(primary: .cyan, secondary: .blue, accent: .white),
        musicDescription: "Bold, adventurous tracks for your journey"
    ),
    
    // FOCUSED MOODS
    EnhancedMood(
        emoji: "🧠",
        imageName: "Focus",
        title: "Focused",
        description: "Concentrated and determined",
        seeds: ["focused", "concentrated", "determined", "productive", "mindful"],
        energy: 0.5,
        category: .focused,
        popularity: 4,
        backgroundColor: MoodColor(primary: .indigo, secondary: .blue, accent: .white),
        accentColor: MoodColor(primary: .blue, secondary: .indigo, accent: .white),
        musicDescription: "Concentrated tracks for deep focus and productivity"
    ),
    
    EnhancedMood(
        emoji: "🎯",
        imageName: "Focus",
        title: "Determined",
        description: "Resolved and persistent",
        seeds: ["determined", "resolved", "persistent", "driven", "ambitious"],
        energy: 0.8,
        category: .focused,
        popularity: 3,
        backgroundColor: MoodColor(primary: .green, secondary: .teal, accent: .white),
        accentColor: MoodColor(primary: .teal, secondary: .green, accent: .white),
        musicDescription: "Driving beats that fuel your determination"
    ),
    
    EnhancedMood(
        emoji: "💪",
        imageName: "Focus",
        title: "Motivated",
        description: "Driven and ambitious",
        seeds: ["motivated", "driven", "ambitious", "goal-oriented", "success"],
        energy: 0.9,
        category: .focused,
        popularity: 4,
        backgroundColor: MoodColor(primary: .orange, secondary: .yellow, accent: .white),
        accentColor: MoodColor(primary: .yellow, secondary: .orange, accent: .white),
        musicDescription: "Motivational tracks that drive you toward success"
    ),
    
    // SOCIAL MOODS
    EnhancedMood(
        emoji: "🎉",
        imageName: "Party",
        title: "Celebratory",
        description: "Ready to party and celebrate",
        seeds: ["celebratory", "party", "celebration", "festive", "joyful"],
        energy: 0.95,
        category: .social,
        popularity: 4,
        backgroundColor: MoodColor(primary: .rainbow, secondary: .gold, accent: .white),
        accentColor: MoodColor(primary: .gold, secondary: .rainbow, accent: .white),
        musicDescription: "Festive, party tracks for celebration"
    ),
    
    EnhancedMood(
        emoji: "🕺",
        imageName: "Party",
        title: "Social",
        description: "Outgoing and friendly",
        seeds: ["social", "outgoing", "friendly", "sociable", "extroverted"],
        energy: 0.8,
        category: .social,
        popularity: 3,
        backgroundColor: MoodColor(primary: .cyan, secondary: .blue, accent: .white),
        accentColor: MoodColor(primary: .blue, secondary: .cyan, accent: .white),
        musicDescription: "Social, friendly tracks for connecting with others"
    ),
    
    EnhancedMood(
        emoji: "🎊",
        imageName: "Party",
        title: "Festive",
        description: "Joyful and celebratory",
        seeds: ["festive", "joyful", "celebratory", "merry", "cheerful"],
        energy: 0.9,
        category: .social,
        popularity: 3,
        backgroundColor: MoodColor(primary: .gold, secondary: .orange, accent: .white),
        accentColor: MoodColor(primary: .orange, secondary: .gold, accent: .white),
        musicDescription: "Joyful, festive music for special occasions"
    ),
    
    // NOSTALGIC MOODS
    EnhancedMood(
        emoji: "🕰️",
        imageName: "Throwback",
        title: "Nostalgic",
        description: "Reminiscing about the past",
        seeds: ["nostalgic", "reminiscing", "memories", "past", "retro"],
        energy: 0.5,
        category: .social,
        popularity: 3,
        backgroundColor: MoodColor(primary: .sepia, secondary: .brown, accent: .white),
        accentColor: MoodColor(primary: .brown, secondary: .sepia, accent: .white),
        musicDescription: "Retro tracks that take you back in time"
    ),
    
    EnhancedMood(
        emoji: "📸",
        imageName: "Throwback",
        title: "Sentimental",
        description: "Emotional and reflective",
        seeds: ["sentimental", "emotional", "reflective", "touching", "heartfelt"],
        energy: 0.4,
        category: .social,
        popularity: 2,
        backgroundColor: MoodColor(primary: .lavender, secondary: .purple, accent: .white),
        accentColor: MoodColor(primary: .purple, secondary: .lavender, accent: .white),
        musicDescription: "Heartfelt songs that touch your soul"
    )
]

// MARK: - Color Extensions
extension Color {
    static let darkRed = Color(red: 0.6, green: 0.1, blue: 0.1)
    static let darkBlue = Color(red: 0.1, green: 0.2, blue: 0.6)
    static let darkGray = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let mint = Color(red: 0.6, green: 1.0, blue: 0.8)
    static let lavender = Color(red: 0.9, green: 0.8, blue: 1.0)
    static let rose = Color(red: 1.0, green: 0.7, blue: 0.8)
    static let gold = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let sepia = Color(red: 0.6, green: 0.5, blue: 0.3)
    static let rainbow = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let magenta = Color(red: 1.0, green: 0.0, blue: 1.0)
}

// MARK: - Helper Functions
func getMoodsByCategory(_ category: MoodCategory) -> [EnhancedMood] {
    return enhancedMoods.filter { $0.category == category }
}

func getPopularMoods() -> [EnhancedMood] {
    return enhancedMoods.filter { $0.popularity >= 4 }
}

func getMoodsByEnergy(min: Double, max: Double) -> [EnhancedMood] {
    return enhancedMoods.filter { $0.energy >= min && $0.energy <= max }
}

func getRandomMood() -> EnhancedMood? {
    return enhancedMoods.randomElement()
}
