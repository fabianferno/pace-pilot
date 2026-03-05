import Foundation
import Combine

@MainActor
final class ActiveRunViewModel: ObservableObject {
    @Published var pace: String = "--:--"
    @Published var distanceKm: Double = 0
    @Published var elapsedSeconds: Int = 0
    @Published var heartRate: Double = 0
    @Published var agentSpeaking = false
    @Published var isRunning = false
    @Published var error: String?

    private let voice = VoiceSessionService.shared
    private let health = HealthKitService.shared
    private let location = LocationService.shared
    private let workout = WorkoutService.shared
    private let watch = WatchConnectivityManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        location.$currentPaceSecondsPerKm
            .map { PaceFormatter.format(secondsPerKm: $0) }
            .assign(to: &$pace)
        location.$distanceKm.assign(to: &$distanceKm)
        workout.$elapsedSeconds.assign(to: &$elapsedSeconds)
        health.$heartRate.assign(to: &$heartRate)
        voice.$agentSpeaking.assign(to: &$agentSpeaking)

        // Forward state to Watch
        Publishers.CombineLatest3(location.$distanceKm, workout.$elapsedSeconds, location.$currentPaceSecondsPerKm)
            .sink { [weak self] dist, elapsed, pace in
                guard let self, self.isRunning else { return }
                let update = RunStateUpdate(distanceKm: dist, elapsedSeconds: elapsed, paceSecondsPerKm: pace, isActive: true)
                self.watch.send(update)
            }
            .store(in: &cancellables)
    }

    func startRun() async {
        do {
            try await health.requestAuthorization()
            try await workout.startWorkout()
            location.startTracking()
            health.startHeartRateUpdates()
            await voice.startSession(type: .activeRun)
            voice.startBiometricStreaming()
            isRunning = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stopRun() async -> NewRunRequest? {
        voice.stopBiometricStreaming()
        await voice.endSession()
        health.stopHeartRateUpdates()
        location.stopTracking()
        _ = try? await workout.endWorkout()

        watch.send(RunStateUpdate(distanceKm: location.distanceKm, elapsedSeconds: workout.elapsedSeconds, paceSecondsPerKm: location.currentPaceSecondsPerKm, isActive: false))
        isRunning = false

        return NewRunRequest(
            workoutId: nil,
            startedAt: Date().addingTimeInterval(-Double(workout.elapsedSeconds)),
            endedAt: Date(),
            distanceKm: location.distanceKm,
            durationSeconds: workout.elapsedSeconds,
            avgPaceSecondsPerKm: location.currentPaceSecondsPerKm,
            avgHeartRate: Int(health.heartRate),
            maxHeartRate: Int(health.heartRate),
            calories: Int(workout.calories),
            elevationGainMeters: workout.elevationGain,
            splits: [],
            gpsTrack: location.gpsTrack
        )
    }
}
