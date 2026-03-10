import Foundation
import Combine

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var plan: TrainingPlan?
    @Published var workouts: [Workout] = []
    @Published var completedRuns: [RunSession] = []
    @Published var selectedWorkout: Workout?
    @Published var isLoading = false

    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            plan = try await api.get("/api/plans/active")
            if let id = plan?.id {
                workouts = try await api.get("/api/plans/\(id)/workouts")
            }
            completedRuns = (try? await api.get("/api/runs")) ?? []
            NotificationService.shared.scheduleWorkoutReminders(for: workouts)
        } catch {}
    }

    /// Dates that have a scheduled workout
    var workoutDates: Set<DateComponents> {
        Set(workouts.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.scheduledDate) })
    }

    /// Dates that have a completed run
    var completedRunDates: Set<DateComponents> {
        Set(completedRuns.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.startedAt) })
    }

    func hasWorkout(on date: Date) -> Bool {
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return workoutDates.contains(dc)
    }

    func hasCompletedRun(on date: Date) -> Bool {
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return completedRunDates.contains(dc)
    }

    func runs(on date: Date) -> [RunSession] {
        completedRuns.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: date) }
    }

    func skipWorkout(_ id: String) async {
        struct Empty: Decodable {}
        _ = try? await api.patch("/api/workouts/\(id)/skip", body: EmptyBody()) as Empty
        await load()
    }

    struct EmptyBody: Encodable {}
}
