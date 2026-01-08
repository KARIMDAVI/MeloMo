import UIKit

/// Enhanced haptic feedback system for MeloMo
enum Haptics {
    
    // MARK: - Basic Haptics
    static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    // MARK: - Music-Specific Haptics
    static func moodSelected() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    
    static func playlistGenerated() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    // MARK: - Navigation Haptics
    static func tabChanged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func menuOpened() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    
    // MARK: - Interactive Haptics
    static func buttonPress() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func sliderChanged() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    
    static func toggleChanged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // MARK: - Custom Haptic Patterns
    static func successPattern() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    static func moodDiscoveryPattern() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        // Pattern: medium → light → soft
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
    
    // MARK: - Haptic Intensity Control
    static func impact(intensity: CGFloat) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        
        switch intensity {
        case 0.0..<0.25:
            style = .soft
        case 0.25..<0.5:
            style = .light
        case 0.5..<0.75:
            style = .medium
        case 0.75...1.0:
            style = .heavy
        default:
            style = .medium
        }
        
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
