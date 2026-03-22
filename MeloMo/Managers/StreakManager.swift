// StreakManager.swift — Consecutive-day activity streak tracker.
// Persists to UserDefaults — two integers and a date don't need SwiftData.
// "Activity" = generating any playlist. Simple, honest, motivating.
import Foundation
import UserNotifications

@MainActor
final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published var currentStreak: Int
    @Published var longestStreak: Int

    private let defaults = UserDefaults.standard

    private var lastActivityDate: Date? {
        get { defaults.object(forKey: "lastActivityDate") as? Date }
        set { defaults.set(newValue, forKey: "lastActivityDate") }
    }

    private init() {
        currentStreak = defaults.integer(forKey: "currentStreak")
        longestStreak = defaults.integer(forKey: "longestStreak")
    }

    /// Call whenever the user generates a playlist. Idempotent within a day.
    func recordActivity() {
        let now = Date()
        let calendar = Calendar.current

        if let last = lastActivityDate {
            let daysSince = calendar.dateComponents([.day], from: last, to: now).day ?? 0

            switch daysSince {
            case 0:   return            // Already logged today — streak unchanged
            case 1:   currentStreak += 1 // Perfect consecutive day
            default:  currentStreak = 1  // Gap found — restart
            }
        } else {
            currentStreak = 1   // First-ever activity
        }

        lastActivityDate = now
        longestStreak = max(longestStreak, currentStreak)
        defaults.set(currentStreak, forKey: "currentStreak")
        defaults.set(longestStreak, forKey: "longestStreak")
    }

    /// Schedule a daily 8pm reminder to pick a mood.
    /// Called once at launch — UNUserNotificationCenter deduplicates by identifier.
    func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_vibe_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "What's your vibe today? 🎵"
        content.body = "Pick a mood and MeloMo will find the perfect soundtrack."
        content.sound = .default

        var time = DateComponents()
        time.hour = 20   // 8pm — respectful but memorable
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_vibe_reminder",
                                            content: content, trigger: trigger)
        center.add(request) { _ in }  // Completion handler version — works in sync context; errors expected if denied
    }
}
