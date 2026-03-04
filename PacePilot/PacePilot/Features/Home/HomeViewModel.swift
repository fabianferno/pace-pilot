import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todaysWorkout: Workout?
    @Published var weeklyDistanceKm: Double = 0
    @Published var weeklyRuns: Int = 0
    @Published var isLoading = false
    @Published var error: String?

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            todaysWorkout = try await api.get("/api/workouts/today")
        } catch {
            self.error = error.localizedDescription
        }
        do {
            struct Stats: Decodable { let weeklyDistanceKm: Double; let weeklyRuns: Int }
            let stats: Stats = try await api.get("/api/users/me/stats")
            weeklyDistanceKm = stats.weeklyDistanceKm
            weeklyRuns = stats.weeklyRuns
        } catch {}
    }
}
