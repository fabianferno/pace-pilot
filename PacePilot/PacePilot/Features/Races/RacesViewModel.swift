import Foundation
import Combine

@MainActor
final class RacesViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var isLoading = false
    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        races = (try? await api.get("/api/races/discover")) ?? []
        isLoading = false
    }

    func markInterest(_ raceId: String) async {
        struct Empty: Decodable {}
        struct EmptyBody: Encodable {}
        _ = try? await api.post("/api/races/\(raceId)/register-interest", body: EmptyBody()) as Empty
        if let idx = races.firstIndex(where: { $0.id == raceId }) {
            races[idx].isInterestedByUser = true
        }
    }

    func createRace(
        name: String,
        distanceKm: Double,
        date: Date,
        location: String,
        registrationUrl: String?,
        elevationGainMeters: Double?
    ) async throws {
        struct Body: Encodable {
            let name: String
            let distanceKm: Double
            let date: Date
            let location: String
            let registrationUrl: String?
            let elevationGainMeters: Double?
        }
        let body = Body(
            name: name,
            distanceKm: distanceKm,
            date: date,
            location: location,
            registrationUrl: registrationUrl,
            elevationGainMeters: elevationGainMeters
        )
        let created: Race = try await api.post("/api/races", body: body)
        races.insert(created, at: 0)
    }
}
