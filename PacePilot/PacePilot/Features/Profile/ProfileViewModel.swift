import Foundation
import Combine
import UIKit

struct ProfileUpdateRequest: Encodable {
    let displayName: String?
    let weeklyMileageGoal: Double?
    let targetRaceDistance: String?
    let targetRaceDate: Date?
    let restingHr: Int?
    let maxHr: Int?
    let preferredDays: [Int]?
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var saveError: String?

    private let api: APIClient
    private let auth: AuthManager

    init(api: APIClient = .shared, auth: AuthManager = .shared) {
        self.api = api
        self.auth = auth
        user = auth.currentUser
    }

    func load() async {
        isLoading = true
        user = try? await api.get("/api/users/me")
        isLoading = false
    }

    func save(_ request: ProfileUpdateRequest) async {
        isSaving = true
        saveError = nil
        struct OkResponse: Decodable { let ok: Bool }
        do {
            _ = try await api.patch("/api/users/me", body: request) as OkResponse
            user = try? await api.get("/api/users/me")
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }

    func signOut() { auth.signOut() }

    func connectStrava() async {
        struct URLResponse: Decodable { let authUrl: String }
        guard let response: URLResponse = try? await api.get("/api/strava/auth-url"),
              let url = URL(string: response.authUrl) else { return }
        await UIApplication.shared.open(url)
    }
}
