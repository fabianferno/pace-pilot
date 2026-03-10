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
    @Published var selectedTab: Int = 0
    @Published var pendingRunId: String?
    @Published var pendingRaceId: String?
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

    func handleNotificationRoute(_ route: String) {
        guard self.route == .main else { return }
        let parts = route.split(separator: "/").map(String.init)
        switch parts.first {
        case "run":
            if parts.count > 1 { pendingRunId = parts[1] }
            selectedTab = 3
        case "community":
            selectedTab = 2
        case "races":
            if parts.count > 1 { pendingRaceId = parts[1] }
            selectedTab = 3
        case "plan":
            selectedTab = 1
        default:
            break
        }
    }
}
