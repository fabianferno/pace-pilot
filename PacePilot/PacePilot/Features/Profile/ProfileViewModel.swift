import Foundation
import Combine
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
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

    func signOut() { auth.signOut() }

    func connectStrava() async {
        struct URLResponse: Decodable { let authUrl: String }
        guard let response: URLResponse = try? await api.get("/api/strava/auth-url"),
              let url = URL(string: response.authUrl) else { return }
        await UIApplication.shared.open(url)
    }
}
