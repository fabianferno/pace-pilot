import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var runs: [RunSession] = []
    @Published var isLoading = false
    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        runs = (try? await api.get("/api/runs")) ?? []
        isLoading = false
    }
}
