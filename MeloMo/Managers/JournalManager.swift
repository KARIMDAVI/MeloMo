import Foundation
import SwiftData
import MainComponents

@MainActor
final class JournalManager: ObservableObject {
    static let shared = JournalManager()
    
    private var container: ModelContainer?
    private var context: ModelContext?
    
    private init() {
        do {
            container = try ModelContainer(for: JournalEntry.self)
            if let container = container {
                context = ModelContext(container)
            }
        } catch {
            print("Failed to initialize Journal SwiftData container: \(error)")
        }
    }
    
    func logMood(title: String, emoji: String, biometrics: BiometricData? = nil) {
        guard let context = context else { return }
        
        let entry = JournalEntry(moodTitle: title, moodEmoji: emoji, biometrics: biometrics)
        context.insert(entry)
        
        do {
            try context.save()
        } catch {
            print("Failed to save journal entry: \(error)")
        }
    }
}
