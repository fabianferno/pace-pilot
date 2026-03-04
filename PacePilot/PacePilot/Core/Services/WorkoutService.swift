import Foundation
import HealthKit
import Combine

@MainActor
final class WorkoutService: ObservableObject {
    static let shared = WorkoutService()

    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var calories: Double = 0
    @Published private(set) var elevationGain: Double = 0

    private let store = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var startTime: Date?

    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        let session = try HKWorkoutSession(healthStore: store, configuration: config)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: store,
            workoutConfiguration: config
        )
        workoutSession = session
        workoutBuilder = builder
        session.startActivity(with: Date())
        try await builder.beginCollection(at: Date())
        startTime = Date()
        elapsedSeconds = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startTime else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    func endWorkout() async throws -> HKWorkout? {
        timer?.invalidate()
        timer = nil
        guard let session = workoutSession, let builder = workoutBuilder else { return nil }
        session.end()
        try await builder.endCollection(at: Date())
        let workout = try await builder.finishWorkout()
        workoutSession = nil
        workoutBuilder = nil
        return workout
    }
}
