import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var cadence: Double = 0
    @Published private(set) var isAuthorized = false

    private var heartRateQuery: HKAnchoredObjectQuery?

    private let readTypes: Set<HKObjectType> = {
        let types: [HKQuantityTypeIdentifier] = [
            .heartRate, .runningPace, .runningCadence,
            .activeEnergyBurned, .distanceWalkingRunning
        ]
        return Set(types.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
    }()

    private let writeTypes: Set<HKSampleType> = {
        return Set([HKObjectType.workoutType()])
    }()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    func startHeartRateUpdates() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHRSamples(samples)
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHRSamples(samples)
        }
        store.execute(query)
        heartRateQuery = query
    }

    func stopHeartRateUpdates() {
        if let query = heartRateQuery {
            store.stop(query)
        }
        heartRateQuery = nil
    }

    private func processHRSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let latest = samples.last else { return }
        let hr = latest.quantity.doubleValue(for: HKUnit(from: "count/min"))
        Task { @MainActor in self.heartRate = hr }
    }
}
