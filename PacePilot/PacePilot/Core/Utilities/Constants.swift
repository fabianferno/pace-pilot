import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://purple.crevn.xyz"
    }
    enum Keychain {
        static let accessToken = "pacepilot.accessToken"
        static let refreshToken = "pacepilot.refreshToken"
        static let userID = "pacepilot.userID"
    }
    enum Watch {
        static let biometricUpdateInterval: TimeInterval = 3
    }
    enum Run {
        static let biometricStreamInterval: TimeInterval = 5
    }
}
