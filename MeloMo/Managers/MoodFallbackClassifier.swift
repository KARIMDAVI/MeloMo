// MoodFallbackClassifier.swift
// Used when the backend is cold (Render free tier sleeps after 15 min of inactivity).
// NaturalLanguage gives us sentiment score — we map that + keywords to a mood card title.
// Not smart, just fast. The goal is "something reasonable" not "perfect classification".
import NaturalLanguage

struct MoodFallbackClassifier {
    private static let tagger = NLTagger(tagSchemes: [.sentimentScore])

    // Ordered by specificity — first match wins.
    // Real-world user inputs: "help me focus", "im tired", "feeling hype tonight"
    private static let keywords: [(words: [String], mood: String)] = [
        (["focus", "study", "work", "concentrate", "productive", "deep work"], "Focused"),
        (["tired", "sleepy", "slow", "low energy", "exhausted", "drained"],    "Calm"),
        (["happy", "joy", "excited", "great", "awesome", "amazing", "good"],   "Happy"),
        (["sad", "down", "blue", "cry", "heartbreak", "lonely", "miss"],       "Sad"),
        (["angry", "frustrated", "stressed", "overwhelmed", "anxious"],        "Stressed"),
        (["love", "romantic", "date", "cozy", "intimate", "cuddle"],           "Romantic"),
        (["party", "celebrate", "hype", "dance", "club", "banger"],            "Energetic"),
        (["chill", "relax", "vibe", "lofi", "easy", "mellow", "calm"],        "Chill"),
    ]

    /// Returns the closest mood title for the input, or nil if nothing matches well.
    static func classify(_ input: String) -> String? {
        let lower = input.lowercased()

        // Keyword pass first — more reliable than sentiment for specific mood words
        for entry in keywords {
            if entry.words.contains(where: { lower.contains($0) }) {
                return entry.mood
            }
        }

        // Sentiment fallback: positive → Happy, negative → Sad, neutral → Chill
        tagger.string = input
        let (sentiment, _) = tagger.tag(at: input.startIndex, unit: .paragraph, scheme: .sentimentScore)
        guard let score = sentiment.flatMap({ Double($0.rawValue) }) else { return nil }

        if score > 0.3  { return "Happy" }
        if score < -0.3 { return "Sad" }
        return "Chill"
    }
}
