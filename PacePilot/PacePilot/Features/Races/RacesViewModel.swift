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
}
