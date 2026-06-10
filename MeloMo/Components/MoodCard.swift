import SwiftUI

struct MoodCard: View {
    let mood: EnhancedMood
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        VStack {
            Text(mood.emoji)
                .font(.largeTitle)
            Text(mood.title)
                .font(.headline)
                .foregroundColor(ThemeColors.text)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .liquidGlassCard(isSelected: isFavorite)
        .onTapGesture(perform: onTap)
        .overlay(alignment: .topTrailing) {
            Button(action: onFavorite) {
                Text.fa(isFavorite ? Icons.heartSolid : Icons.heart, size: 16)
                    .foregroundColor(isFavorite ? .red : ThemeColors.textSecondary)
            }
            .padding(12)
        }
    }
}

#Preview {
    MoodCard(
        mood: enhancedMoods.first!,
        isFavorite: true,
        onTap: {},
        onFavorite: {}
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
