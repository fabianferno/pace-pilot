import XCTest
@testable import PacePilot

final class UserModelTests: XCTestCase {
    func test_decodesUserFromJSON() throws {
        let json = """
        {"id":"abc123","email":"test@test.com","displayName":"Test Runner",
         "communityTier":"momentum","onboardingComplete":true}
        """.data(using: .utf8)!
        let user = try JSONDecoder().decode(User.self, from: json)
        XCTAssertEqual(user.id, "abc123")
        XCTAssertEqual(user.communityTier, .momentum)
    }
}
