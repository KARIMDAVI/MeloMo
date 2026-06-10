import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: String
    var moodTitle: String
    var moodEmoji: String
    var timestamp: Date
    var note: String?
    
    // Biometric context
    var heartRate: Double?
    var hrv: Double?
    var sleepHours: Double?
    var activityLevel: String?
    
    init(
        id: String = UUID().uuidString,
        moodTitle: String,
        moodEmoji: String,
        timestamp: Date = Date(),
        note: String? = nil,
        biometrics: BiometricData? = nil
    ) {
        self.id = id
        self.moodTitle = moodTitle
        self.moodEmoji = moodEmoji
        self.timestamp = timestamp
        self.note = note
        
        self.heartRate = biometrics?.heartRate
        self.hrv = biometrics?.hrv
        self.sleepHours = biometrics?.sleepHours
        self.activityLevel = biometrics?.activityLevel
    }
}
