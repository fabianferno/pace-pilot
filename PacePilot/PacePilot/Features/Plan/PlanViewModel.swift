import Foundation

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var plan: TrainingPlan?
    @Published var workouts: [Workout] = []
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
        } catch {}
    }

    func skipWorkout(_ id: String) async {
        struct Empty: Decodable {}
        _ = try? await api.patch("/api/workouts/\(id)/skip", body: EmptyBody()) as Empty
        await load()
    }

    struct EmptyBody: Encodable {}
}
