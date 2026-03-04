import Foundation
import HealthKit
import CoreLocation
import Combine

@MainActor
final class WatchWorkoutManager: NSObject, ObservableObject {
    static let shared = WatchWorkoutManager()

    @Published private(set) var heartRate: Double = 0
    @Published private(set) var pace: Double = 0  // seconds/km
    @Published private(set) var isRunning = false

    private let store = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var streamTimer: Timer?

    private let connectivity = WatchConnectivityManager.shared

    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        let session = try HKWorkoutSession(healthStore: store, configuration: config)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
        builder.delegate = self
        workoutSession = session
        workoutBuilder = builder
        session.startActivity(with: Date())
        try await builder.beginCollection(at: Date())
        isRunning = true

        // Stream biometrics to phone every 3s
        streamTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.streamBiometrics() }
        }
    }

    func endWorkout() async throws {
        streamTimer?.invalidate()
        streamTimer = nil
        guard let session = workoutSession, let builder = workoutBuilder else { return }
        session.end()
        try await builder.endCollection(at: Date())
        _ = try? await builder.finishWorkout()
        workoutSession = nil
        workoutBuilder = nil
        isRunning = false
    }

    private func streamBiometrics() {
        let update = BiometricUpdate(
            heartRate: heartRate,
            paceSecondsPerKm: pace,
            timestamp: Date()
        )
        connectivity.sendBiometricUpdate(update)
    }
}

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let stats = workoutBuilder.statistics(for: quantityType)

            switch quantityType {
            case HKQuantityType(.heartRate):
                let bpm = stats?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                Task { @MainActor in self.heartRate = bpm }
            case HKQuantityType(.runningSpeed):
                let mps = stats?.mostRecentQuantity()?.doubleValue(for: HKUnit.meter().unitDivided(by: .second())) ?? 0
                Task { @MainActor in self.pace = mps > 0 ? 1000.0 / mps : 0 }
            default:
                break
            }
        }
    }
}
