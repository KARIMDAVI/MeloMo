import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var lastBiometrics: BiometricData?
    
    private init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        // Simple check if any of the types are authorized
        // Note: HealthKit doesn't give a simple 'authorized' status for reading due to privacy
    }
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func fetchLatestBiometrics() async -> BiometricData? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        
        let hrv = await fetchLatestQuantity(for: .heartRateVariabilitySDNN)
        let hr = await fetchLatestQuantity(for: .heartRate)
        let sleep = await fetchSleepLastNight()
        let activity = await fetchActivityLevel()
        
        let data = BiometricData(
            heartRate: hr,
            hrv: hrv,
            sleepHours: sleep,
            activityLevel: activity,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        
        self.lastBiometrics = data
        return data
    }
    
    private func fetchLatestQuantity(for identifier: HKQuantityTypeIdentifier) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-86400), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let unit = identifier == .heartRate ? HKUnit(from: "count/min") : HKUnit.secondUnit(with: .milli)
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchSleepLastNight() async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay.addingTimeInterval(-86400), end: Date(), options: .strictEndDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: nil) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let totalSeconds = sleepSamples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchActivityLevel() async -> String {
        // Simple heuristic: check if there's a workout in the last 2 hours
        guard let workoutType = HKObjectType.workoutType() else { return "sedentary" }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-7200), end: Date(), options: .strictEndDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 1, sortDescriptors: nil) { _, samples, _ in
                if let _ = samples?.first {
                    continuation.resume(returning: "workout")
                } else {
                    continuation.resume(returning: "active") // Defaulting to active for mock-ish purposes or further refinement
                }
            }
            healthStore.execute(query)
        }
    }
}

struct BiometricData: Codable {
    let heartRate: Double?
    let hrv: Double?
    let sleepHours: Double?
    let activityLevel: String?
    let lastUpdated: String?
}
