// MoodSuggestionRow.swift — Pill chip showing a mood suggestion from NL classification.
// Shows mood name + confidence percentage so the user can pick the most accurate match.
import SwiftUI

struct MoodSuggestionRow: View {
    let suggestion: MoodSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(suggestion.mood)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(String(format: "%.0f%%", suggestion.confidence * 100))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
        }
        .foregroundColor(.white)
    }
}
