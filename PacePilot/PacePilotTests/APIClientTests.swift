import XCTest
@testable import PacePilot

final class APIClientTests: XCTestCase {
    var client: APIClient!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        client = APIClient(session: session)
    }

    func test_getRequest_decodesResponse() async throws {
        let expected = User(id: "1", email: "a@b.com", displayName: "Runner",
                            communityTier: .momentum, onboardingComplete: true,
                            stravaConnected: false, googleCalendarConnected: false)
        MockURLProtocol.requestHandler = { request in
            let data = try JSONEncoder().encode(expected)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                           httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        let user: User = try await client.get("/api/users/me")
        XCTAssertEqual(user.id, "1")
    }

    func test_requestIncludesAuthHeader_whenTokenPresent() async throws {
        KeychainHelper.save("test-token", forKey: Constants.Keychain.accessToken)
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                           httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        _ = try? await client.get("/api/users/me") as User
        XCTAssertNotNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }
}

// MARK: - MockURLProtocol
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { return }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}
