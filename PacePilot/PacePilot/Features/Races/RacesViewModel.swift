import Foundation

@MainActor
final class RunsViewModel: ObservableObject {
    @Published var runs: [CommunityRun] = []
    @Published var isLoading = false
    private let api: APIClient

    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        runs = (try? await api.get("/api/community-runs/discover")) ?? []
        isLoading = false
    }

    func rsvp(_ runId: String) async {
        struct Empty: Decodable {}
        struct EmptyBody: Encodable {}
        _ = try? await api.post("/api/community-runs/\(runId)/rsvp", body: EmptyBody()) as Empty
        if let idx = runs.firstIndex(where: { $0.id == runId }) {
            runs[idx].isRsvpdByUser = true
            runs[idx].rsvpCount += 1
        }
    }

    func unrsvp(_ runId: String) async {
        try? await api.delete("/api/community-runs/\(runId)/rsvp")
        if let idx = runs.firstIndex(where: { $0.id == runId }) {
            runs[idx].isRsvpdByUser = false
            runs[idx].rsvpCount = max(0, runs[idx].rsvpCount - 1)
        }
    }

    func createRun(
        name: String,
        distanceKm: Double,
        date: Date,
        location: String,
        city: String,
        latitude: Double,
        longitude: Double
    ) async throws {
        struct Body: Encodable {
            let name: String
            let distanceKm: Double
            let date: Date
            let location: String
            let city: String
            let latitude: Double
            let longitude: Double
        }
        let body = Body(
            name: name, distanceKm: distanceKm, date: date,
            location: location, city: city,
            latitude: latitude, longitude: longitude
        )
        let created: CommunityRun = try await api.post("/api/community-runs", body: body)
        runs.insert(created, at: 0)
    }
}
