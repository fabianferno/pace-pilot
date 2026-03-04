import SwiftUI
import Combine

enum AppRoute {
    case splash
    case onboarding
    case main
}

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var route: AppRoute = .splash
    private var cancellables = Set<AnyCancellable>()
    private let auth: AuthManager

    init(auth: AuthManager = .shared) {
        self.auth = auth
        auth.$authState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                switch state {
                case .unauthenticated:
                    self?.route = .splash
                case .tokenPresent:
                    break // wait for validateSession
                case .authenticated(let user):
                    self?.route = user.onboardingComplete ? .main : .onboarding
                }
            }
            .store(in: &cancellables)
    }
}
