import Foundation
import AuthenticationServices
import Combine

enum AuthState: Equatable {
    case unauthenticated
    case tokenPresent      // token in keychain, not yet validated
    case authenticated(User)
}

@MainActor
final class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var authState: AuthState = .unauthenticated
    @Published private(set) var currentUser: User?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        super.init()
        if KeychainHelper.load(forKey: Constants.Keychain.accessToken) != nil {
            authState = .tokenPresent
        }
    }

    /// Call on app launch to validate stored token
    func validateSession() async {
        guard authState == .tokenPresent else { return }
        do {
            let user: User = try await apiClient.get("/api/users/me")
            currentUser = user
            authState = .authenticated(user)
        } catch APIError.unauthorized {
            signOut()
        } catch {
            // Network error — keep tokenPresent, will retry
        }
    }

    /// Initiate Apple Sign-In
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    func signOut() {
        KeychainHelper.delete(forKey: Constants.Keychain.accessToken)
        KeychainHelper.delete(forKey: Constants.Keychain.refreshToken)
        KeychainHelper.delete(forKey: Constants.Keychain.userID)
        currentUser = nil
        authState = .unauthenticated
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else { return }

        Task {
            await exchangeAppleToken(identityToken, fullName: credential.fullName)
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        print("Apple Sign-In error: \(error)")
    }

    private func exchangeAppleToken(_ token: String, fullName: PersonNameComponents?) async {
        struct AppleAuthRequest: Encodable {
            let identityToken: String
            let displayName: String?
        }
        struct AuthResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let user: User
        }
        let name = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")
        let body = AppleAuthRequest(identityToken: token, displayName: name.isEmpty ? nil : name)
        do {
            let response: AuthResponse = try await apiClient.post("/api/auth/apple", body: body)
            KeychainHelper.save(response.accessToken, forKey: Constants.Keychain.accessToken)
            KeychainHelper.save(response.refreshToken, forKey: Constants.Keychain.refreshToken)
            KeychainHelper.save(response.user.id, forKey: Constants.Keychain.userID)
            currentUser = response.user
            authState = .authenticated(response.user)
        } catch {
            print("Auth exchange error: \(error)")
        }
    }
}
