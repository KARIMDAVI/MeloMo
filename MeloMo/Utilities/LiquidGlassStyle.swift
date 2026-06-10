import SwiftUI

// MARK: - Theme Colors
struct ThemeColors {
    static let primaryAccent = Color(red: 0, green: 0.8, blue: 1) // Electric Blue
    static let secondaryAccent = Color(red: 0.5, green: 0.5, blue: 1) // Soft Purple
    static let background = Color.black
    static let surface = Color.white.opacity(0.05)
    static let text = Color.white
    static let textSecondary = Color.white.opacity(0.7)
}

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05),
                                        ThemeColors.surface
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            )
    }
}

// MARK: - Liquid Glass Card Modifier
struct LiquidGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [ThemeColors.primaryAccent.opacity(0.5), ThemeColors.secondaryAccent.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [ThemeColors.surface, ThemeColors.surface.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        isSelected ? ThemeColors.primaryAccent.opacity(0.8) : Color.white.opacity(0.2),
                                        isSelected ? ThemeColors.secondaryAccent.opacity(0.6) : Color.white.opacity(0.05),
                                        ThemeColors.surface
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? ThemeColors.primaryAccent.opacity(0.3) : .black.opacity(0.2),
                        radius: isSelected ? 16 : 10,
                        x: 0,
                        y: isSelected ? 8 : 5
                    )
            )
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlass(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
    
    func liquidGlassCard(cornerRadius: CGFloat = 16, isSelected: Bool = false) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, isSelected: isSelected))
    }
}
