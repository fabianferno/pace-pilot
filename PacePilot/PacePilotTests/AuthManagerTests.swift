import XCTest
@testable import PacePilot

final class AuthManagerTests: XCTestCase {
    func test_initialStateIsUnauthenticated_whenNoTokenStored() {
        KeychainHelper.delete(forKey: Constants.Keychain.accessToken)
        let manager = AuthManager()
        XCTAssertEqual(manager.authState, .unauthenticated)
    }

    func test_initialStateIsAuthenticated_whenTokenStored() {
        KeychainHelper.save("valid-token", forKey: Constants.Keychain.accessToken)
        let manager = AuthManager()
        XCTAssertEqual(manager.authState, .tokenPresent)
        KeychainHelper.delete(forKey: Constants.Keychain.accessToken)
    }

    func test_signOut_clearsKeychain() {
        KeychainHelper.save("some-token", forKey: Constants.Keychain.accessToken)
        let manager = AuthManager()
        manager.signOut()
        XCTAssertNil(KeychainHelper.load(forKey: Constants.Keychain.accessToken))
        XCTAssertEqual(manager.authState, .unauthenticated)
    }
}
