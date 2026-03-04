# PacePilot iOS App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the full PacePilot iOS + watchOS app — a voice-first AI running coach powered by Gemini Live via a Pipecat backend.

**Architecture:** Layer-by-layer: Core infrastructure (models, networking, services) built first with unit tests, then Feature SwiftUI modules, then navigation shell. All real-time data flows use Combine publishers; voice sessions use Daily.co WebRTC.

**Tech Stack:** Swift 5.9+, SwiftUI, Combine, HealthKit, CoreLocation, WatchConnectivity, EventKit, Daily.co iOS SDK (SPM), XCTest

---

> **Xcode Note:** After writing Swift files, open Xcode and drag new files into the correct Group in the Project Navigator, ensuring the correct target membership is checked. This must be done after each task group.

---

## Phase 1: Project Setup

### Task 1: Add Daily.co SDK via Swift Package Manager

**Files:**
- Modify: `PacePilot/PacePilot.xcodeproj/project.pbxproj` (via Xcode UI)

**Step 1: Open Xcode and add package**

In Xcode: File → Add Package Dependencies
URL: `https://github.com/daily-co/daily-client-ios`
Version: Up To Next Major from `0.21.0`
Add to target: `PacePilot`

**Step 2: Enable capabilities in Xcode**

PacePilot target → Signing & Capabilities → add:
- Background Modes: Audio, AirPlay, Picture in Picture; Location updates
- HealthKit
- Push Notifications (for future use)

PacePilotWatch target → add:
- HealthKit

**Step 3: Update Info.plist permissions**

Add to `PacePilot/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>PacePilot uses your microphone for voice coaching during runs.</string>
<key>NSHealthShareUsageDescription</key>
<string>PacePilot reads heart rate, pace, and workout data to coach you.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>PacePilot saves your workouts to Apple Health.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>PacePilot tracks your route and calculates pace during runs.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>PacePilot tracks your route during background runs.</string>
```

**Step 4: Commit**
```bash
git add PacePilot/PacePilot/Info.plist
git commit -m "feat: configure capabilities and permissions for PacePilot"
```

---

### Task 2: Create directory structure

**Step 1: Create Core directories**
```bash
mkdir -p PacePilot/PacePilot/Core/Models
mkdir -p PacePilot/PacePilot/Core/Network
mkdir -p PacePilot/PacePilot/Core/Services
mkdir -p PacePilot/PacePilot/Core/Utilities
mkdir -p PacePilot/PacePilot/App
mkdir -p PacePilot/PacePilot/Features/Onboarding
mkdir -p PacePilot/PacePilot/Features/Home
mkdir -p PacePilot/PacePilot/Features/Plan
mkdir -p PacePilot/PacePilot/Features/ActiveRun
mkdir -p PacePilot/PacePilot/Features/PostRun
mkdir -p PacePilot/PacePilot/Features/Community
mkdir -p PacePilot/PacePilot/Features/Races
mkdir -p PacePilot/PacePilot/Features/History
mkdir -p PacePilot/PacePilot/Features/Profile
mkdir -p "PacePilot/PacePilotWatch Watch App/Views"
mkdir -p "PacePilot/PacePilotWatch Watch App/Services"
mkdir -p "PacePilot/PacePilotWatch Watch App/Models"
```

**Step 2: Commit**
```bash
git add -A
git commit -m "chore: create iOS and Watch app directory structure"
```

---

## Phase 2: Core Models

### Task 3: Utilities — Constants, PaceFormatter, TimeFormatter

**Files:**
- Create: `PacePilot/PacePilot/Core/Utilities/Constants.swift`
- Create: `PacePilot/PacePilot/Core/Utilities/PaceFormatter.swift`
- Create: `PacePilot/PacePilot/Core/Utilities/TimeFormatter.swift`
- Test: `PacePilot/PacePilotTests/UtilitiesTests.swift`

**Step 1: Write failing tests**

```swift
// PacePilotTests/UtilitiesTests.swift
import XCTest
@testable import PacePilot

final class PaceFormatterTests: XCTestCase {
    func test_formatsPaceFromSecondsPerKm() {
        XCTAssertEqual(PaceFormatter.format(secondsPerKm: 272), "4:32")
    }
    func test_formatsSubFiveMinutePace() {
        XCTAssertEqual(PaceFormatter.format(secondsPerKm: 240), "4:00")
    }
    func test_formatsSlowPace() {
        XCTAssertEqual(PaceFormatter.format(secondsPerKm: 450), "7:30")
    }
}

final class RunTimeFormatterTests: XCTestCase {
    func test_formatsUnderOneHour() {
        XCTAssertEqual(RunTimeFormatter.format(seconds: 1425), "23:45")
    }
    func test_formatsOverOneHour() {
        XCTAssertEqual(RunTimeFormatter.format(seconds: 5025), "1:23:45")
    }
}
```

**Step 2: Run tests to verify they fail**
```bash
xcodebuild test -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PacePilotTests/PaceFormatterTests 2>&1 | tail -20
```
Expected: FAIL — `PaceFormatter` not found

**Step 3: Write Constants.swift**

```swift
// Core/Utilities/Constants.swift
import Foundation

enum Constants {
    enum API {
        static let baseURL = "http://localhost:8000"
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
```

**Step 4: Write PaceFormatter.swift**

```swift
// Core/Utilities/PaceFormatter.swift
import Foundation

enum PaceFormatter {
    /// Formats seconds-per-km as "M:SS"
    static func format(secondsPerKm: Double) -> String {
        let total = Int(secondsPerKm)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formats pace in m/s (from CoreLocation) to "M:SS/km"
    static func fromMetersPerSecond(_ mps: Double) -> String {
        guard mps > 0 else { return "--:--" }
        let secondsPerKm = 1000.0 / mps
        return format(secondsPerKm: secondsPerKm)
    }
}
```

**Step 5: Write TimeFormatter.swift**

```swift
// Core/Utilities/TimeFormatter.swift
import Foundation

enum RunTimeFormatter {
    /// Formats elapsed seconds as "M:SS" or "H:MM:SS"
    static func format(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
}
```

**Step 6: Run tests to verify they pass**
```bash
xcodebuild test -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PacePilotTests/PaceFormatterTests -only-testing:PacePilotTests/RunTimeFormatterTests 2>&1 | tail -10
```
Expected: PASS

**Step 7: Commit**
```bash
git add PacePilot/PacePilot/Core/Utilities/ PacePilot/PacePilotTests/UtilitiesTests.swift
git commit -m "feat: add PaceFormatter, RunTimeFormatter, Constants with tests"
```

---

### Task 4: Core Data Models

**Files:**
- Create: `PacePilot/PacePilot/Core/Models/User.swift`
- Create: `PacePilot/PacePilot/Core/Models/TrainingPlan.swift`
- Create: `PacePilot/PacePilot/Core/Models/Workout.swift`
- Create: `PacePilot/PacePilot/Core/Models/RunSession.swift`
- Create: `PacePilot/PacePilot/Core/Models/Community.swift`
- Create: `PacePilot/PacePilot/Core/Models/Race.swift`
- Create: `PacePilot/PacePilot/Core/Models/AgentSession.swift`
- Create: `PacePilot/PacePilot/Core/Models/WatchMessage.swift`
- Test: `PacePilot/PacePilotTests/ModelTests.swift`

**Step 1: Write failing tests**

```swift
// PacePilotTests/ModelTests.swift
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
```

**Step 2: Run to verify failure**
```bash
xcodebuild test -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PacePilotTests/UserModelTests 2>&1 | tail -5
```

**Step 3: Write User.swift**

```swift
// Core/Models/User.swift
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var displayName: String
    var communityTier: CommunityTier
    var onboardingComplete: Bool
    var stravaConnected: Bool
    var googleCalendarConnected: Bool
    var weeklyMileageGoal: Double?
    var targetRaceDistance: String?
    var targetRaceDate: Date?

    enum CommunityTier: String, Codable {
        case discovery, foundation, momentum, velocity, elite
    }
}
```

**Step 4: Write TrainingPlan.swift**

```swift
// Core/Models/TrainingPlan.swift
import Foundation

struct TrainingPlan: Codable, Identifiable {
    let id: String
    let userId: String
    let startDate: Date
    let endDate: Date
    let phase: Phase
    let paceZones: PaceZones
    let hrZones: HRZones
    let weeklyWorkouts: [String: [String]] // week number -> workout IDs
    var isActive: Bool

    enum Phase: String, Codable {
        case base, build, peak, taper, recovery
    }

    struct PaceZones: Codable {
        let easy: Double        // seconds/km
        let marathon: Double
        let threshold: Double
        let interval: Double
        let repetition: Double
    }

    struct HRZones: Codable {
        let zone1Max: Int
        let zone2Max: Int
        let zone3Max: Int
        let zone4Max: Int
        let zone5Max: Int
    }
}
```

**Step 5: Write Workout.swift**

```swift
// Core/Models/Workout.swift
import Foundation

struct Workout: Codable, Identifiable {
    let id: String
    let planId: String
    let scheduledDate: Date
    let type: WorkoutType
    let targetDistanceKm: Double
    let targetPaceZone: String
    let segments: [Segment]
    var isCompleted: Bool
    var isSkipped: Bool

    enum WorkoutType: String, Codable {
        case easy, tempo, interval, long, recovery, race
    }

    struct Segment: Codable {
        let distanceKm: Double
        let paceZone: String
        let description: String
    }
}
```

**Step 6: Write RunSession.swift**

```swift
// Core/Models/RunSession.swift
import Foundation
import CoreLocation

struct RunSession: Codable, Identifiable {
    let id: String
    let userId: String
    let workoutId: String?
    let startedAt: Date
    let endedAt: Date
    let distanceKm: Double
    let durationSeconds: Int
    let avgPaceSecondsPerKm: Double
    let avgHeartRate: Int
    let maxHeartRate: Int
    let calories: Int
    let elevationGainMeters: Double
    let splits: [Split]
    let gpsTrack: [GPSPoint]
    var stravaActivityId: String?

    struct Split: Codable {
        let kmNumber: Int
        let paceSecondsPerKm: Double
        let avgHeartRate: Int
    }

    struct GPSPoint: Codable {
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let timestamp: Date
    }
}

// Used for submitting a new run
struct NewRunRequest: Codable {
    let workoutId: String?
    let startedAt: Date
    let endedAt: Date
    let distanceKm: Double
    let durationSeconds: Int
    let avgPaceSecondsPerKm: Double
    let avgHeartRate: Int
    let maxHeartRate: Int
    let calories: Int
    let elevationGainMeters: Double
    let splits: [RunSession.Split]
    let gpsTrack: [RunSession.GPSPoint]
}
```

**Step 7: Write Community.swift**

```swift
// Core/Models/Community.swift
import Foundation

struct Community: Codable, Identifiable {
    let id: String
    let tier: User.CommunityTier
    let name: String
    let memberCount: Int
    let challenges: [Challenge]
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let weeklyDistanceKm: Double
    let rank: Int
}

struct Challenge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let targetKm: Double
    let endDate: Date
}

struct FriendActivity: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let distanceKm: Double
    let paceSecondsPerKm: Double
    let completedAt: Date
}
```

**Step 8: Write Race.swift**

```swift
// Core/Models/Race.swift
import Foundation

struct Race: Codable, Identifiable {
    let id: String
    let name: String
    let distanceKm: Double
    let date: Date
    let location: String
    let registrationURL: String?
    let elevationGainMeters: Double?
    var isInterestedByUser: Bool
}
```

**Step 9: Write AgentSession.swift**

```swift
// Core/Models/AgentSession.swift
import Foundation

struct AgentSession: Codable, Identifiable {
    let id: String
    let userId: String
    let sessionType: SessionType
    let startedAt: Date
    let endedAt: Date?
    let transcript: [TranscriptEntry]

    enum SessionType: String, Codable {
        case onboarding, preRun = "pre_run", activeRun = "active_run", postRun = "post_run", general
    }

    struct TranscriptEntry: Codable, Identifiable {
        let id: String
        let role: String  // "agent" | "user"
        let content: String
        let timestamp: Date
    }
}
```

**Step 10: Write WatchMessage.swift (Shared)**

```swift
// Shared/WatchMessage.swift (replace existing Shared.swift content)
import Foundation

enum WatchMessageType: String, Codable {
    case biometricUpdate
    case runCommand
    case voiceInput
    case runStateUpdate
    case hapticTrigger
    case workoutSync
}

struct BiometricUpdate: Codable {
    let heartRate: Double
    let paceSecondsPerKm: Double
    let timestamp: Date
}

struct RunCommand: Codable {
    enum Command: String, Codable { case start, pause, stop }
    let command: Command
}

struct RunStateUpdate: Codable {
    let distanceKm: Double
    let elapsedSeconds: Int
    let paceSecondsPerKm: Double
    let isActive: Bool
}

struct HapticTrigger: Codable {
    enum HapticType: String, Codable {
        case intervalStart, intervalEnd, milestone, paceAlert, heartRateAlert
    }
    let type: HapticType
}

struct WorkoutSync: Codable {
    let workoutType: String
    let targetDistanceKm: Double
    let targetPaceZone: String
}
```

**Step 11: Run model tests**
```bash
xcodebuild test -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PacePilotTests/UserModelTests 2>&1 | tail -10
```
Expected: PASS

**Step 12: Commit**
```bash
git add PacePilot/PacePilot/Core/Models/ PacePilot/Shared/ PacePilot/PacePilotTests/ModelTests.swift
git commit -m "feat: add all core data models with Codable conformance"
```

---

## Phase 3: Networking

### Task 5: APIClient

**Files:**
- Create: `PacePilot/PacePilot/Core/Network/APIClient.swift`
- Test: `PacePilot/PacePilotTests/APIClientTests.swift`

**Step 1: Write failing tests**

```swift
// PacePilotTests/APIClientTests.swift
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
```

**Step 2: Write KeychainHelper**

```swift
// Core/Utilities/KeychainHelper.swift
import Foundation
import Security

enum KeychainHelper {
    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

**Step 3: Write APIClient.swift**

```swift
// Core/Network/APIClient.swift
import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code, _): return "HTTP \(code)"
        case .decodingError(let e): return e.localizedDescription
        case .unauthorized: return "Unauthorized"
        }
    }
}

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(session: URLSession = .shared, baseURL: String = Constants.API.baseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(method: "GET", path: path, body: nil as String?)
    }

    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        try await request(method: "POST", path: path, body: body)
    }

    func patch<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        try await request(method: "PATCH", path: path, body: body)
    }

    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(method: "DELETE", path: path, body: nil as String?)
    }

    private func request<Body: Encodable, T: Decodable>(
        method: String, path: String, body: Body?
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.load(forKey: Constants.Keychain.accessToken) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }

        switch http.statusCode {
        case 200...299:
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.httpError(statusCode: http.statusCode, data: data)
        }
    }
}

private struct EmptyResponse: Codable {}
```

**Step 4: Run tests**
```bash
xcodebuild test -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PacePilotTests/APIClientTests 2>&1 | tail -10
```
Expected: PASS

**Step 5: Commit**
```bash
git add PacePilot/PacePilot/Core/Network/APIClient.swift PacePilot/PacePilot/Core/Utilities/KeychainHelper.swift PacePilot/PacePilotTests/APIClientTests.swift
git commit -m "feat: add APIClient with JWT injection and KeychainHelper"
```

---

### Task 6: AuthManager

**Files:**
- Create: `PacePilot/PacePilot/Core/AuthManager.swift`
- Test: `PacePilot/PacePilotTests/AuthManagerTests.swift`

**Step 1: Write failing test**

```swift
// PacePilotTests/AuthManagerTests.swift
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
```

**Step 2: Write AuthManager.swift**

```swift
// Core/AuthManager.swift
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
```

**Step 3: Run tests**
```bash
xcodebuild test -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PacePilotTests/AuthManagerTests 2>&1 | tail -10
```

**Step 4: Commit**
```bash
git add PacePilot/PacePilot/Core/AuthManager.swift PacePilot/PacePilotTests/AuthManagerTests.swift
git commit -m "feat: add AuthManager with Apple Sign-In and Keychain token storage"
```

---

## Phase 4: Core Services

### Task 7: HealthKitService

**Files:**
- Create: `PacePilot/PacePilot/Core/Services/HealthKitService.swift`

```swift
// Core/Services/HealthKitService.swift
import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var cadence: Double = 0
    @Published private(set) var isAuthorized = false

    private var heartRateQuery: HKAnchoredObjectQuery?

    private let readTypes: Set<HKObjectType> = {
        let types: [HKQuantityTypeIdentifier] = [
            .heartRate, .runningPace, .runningCadence,
            .activeEnergyBurned, .distanceWalkingRunning
        ]
        return Set(types.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
    }()

    private let writeTypes: Set<HKSampleType> = {
        return Set([HKObjectType.workoutType()])
    }()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    func startHeartRateUpdates() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHRSamples(samples)
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHRSamples(samples)
        }
        store.execute(query)
        heartRateQuery = query
    }

    func stopHeartRateUpdates() {
        if let query = heartRateQuery {
            store.stop(query)
        }
        heartRateQuery = nil
    }

    private func processHRSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let latest = samples.last else { return }
        let hr = latest.quantity.doubleValue(for: HKUnit(from: "count/min"))
        Task { @MainActor in self.heartRate = hr }
    }
}
```

**Step 2: Commit**
```bash
git add PacePilot/PacePilot/Core/Services/HealthKitService.swift
git commit -m "feat: add HealthKitService for real-time HR and HealthKit authorization"
```

---

### Task 8: LocationService

**Files:**
- Create: `PacePilot/PacePilot/Core/Services/LocationService.swift`

```swift
// Core/Services/LocationService.swift
import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var currentPaceSecondsPerKm: Double = 0
    @Published private(set) var distanceKm: Double = 0
    @Published private(set) var gpsTrack: [RunSession.GPSPoint] = []

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var isTracking = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        isTracking = true
        distanceKm = 0
        gpsTrack = []
        lastLocation = nil
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, let location = locations.last else { return }
        let point = RunSession.GPSPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp
        )
        gpsTrack.append(point)

        if let last = lastLocation {
            let delta = location.distance(from: last) / 1000.0
            distanceKm += delta
        }
        lastLocation = location

        // Pace from CLLocation speed (m/s)
        if location.speed > 0.5 {
            currentPaceSecondsPerKm = 1000.0 / location.speed
        }
    }
}
```

**Step 2: Commit**
```bash
git add PacePilot/PacePilot/Core/Services/LocationService.swift
git commit -m "feat: add LocationService for GPS tracking and pace calculation"
```

---

### Task 9: WorkoutService

**Files:**
- Create: `PacePilot/PacePilot/Core/Services/WorkoutService.swift`

```swift
// Core/Services/WorkoutService.swift
import Foundation
import HealthKit
import Combine

@MainActor
final class WorkoutService: ObservableObject {
    static let shared = WorkoutService()

    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var calories: Double = 0
    @Published private(set) var elevationGain: Double = 0

    private let store = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var startTime: Date?

    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        let session = try HKWorkoutSession(healthStore: store, configuration: config)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: store,
            workoutConfiguration: config
        )
        workoutSession = session
        workoutBuilder = builder
        session.startActivity(with: Date())
        try await builder.beginCollection(at: Date())
        startTime = Date()
        elapsedSeconds = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startTime else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    func endWorkout() async throws -> HKWorkout? {
        timer?.invalidate()
        timer = nil
        guard let session = workoutSession, let builder = workoutBuilder else { return nil }
        session.end()
        try await builder.endCollection(at: Date())
        let workout = try await builder.finishWorkout()
        workoutSession = nil
        workoutBuilder = nil
        return workout
    }
}
```

**Step 2: Commit**
```bash
git add PacePilot/PacePilot/Core/Services/WorkoutService.swift
git commit -m "feat: add WorkoutService for HKWorkoutSession lifecycle"
```

---

### Task 10: VoiceSessionService

**Files:**
- Create: `PacePilot/PacePilot/Core/Services/VoiceSessionService.swift`

```swift
// Core/Services/VoiceSessionService.swift
import Foundation
import Combine
import Daily

enum VoiceSessionState: Equatable {
    case idle, connecting, active, disconnecting, error(String)
}

@MainActor
final class VoiceSessionService: NSObject, ObservableObject {
    static let shared = VoiceSessionService()

    @Published private(set) var sessionState: VoiceSessionState = .idle
    @Published private(set) var agentSpeaking = false

    private let apiClient: APIClient
    private var callClient: CallClient?
    private var biometricTimer: Timer?
    private var currentSessionId: String?

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func startSession(type: AgentSession.SessionType) async {
        sessionState = .connecting
        do {
            struct SessionRequest: Encodable { let sessionType: String }
            struct SessionResponse: Decodable { let roomUrl: String; let token: String; let sessionId: String }
            let body = SessionRequest(sessionType: type.rawValue)
            let response: SessionResponse = try await apiClient.post("/api/voice/session", body: body)
            currentSessionId = response.sessionId
            await connectToDaily(roomURL: response.roomUrl, token: response.token)
        } catch {
            sessionState = .error(error.localizedDescription)
        }
    }

    func endSession() async {
        sessionState = .disconnecting
        stopBiometricStreaming()
        callClient?.leave()
        if let id = currentSessionId {
            struct EndRequest: Encodable { let sessionId: String }
            _ = try? await apiClient.post("/api/voice/end", body: EndRequest(sessionId: id)) as AgentSession
        }
        currentSessionId = nil
        sessionState = .idle
    }

    func startBiometricStreaming() {
        biometricTimer = Timer.scheduledTimer(withTimeInterval: Constants.Run.biometricStreamInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in await self?.streamBiometrics() }
        }
    }

    func stopBiometricStreaming() {
        biometricTimer?.invalidate()
        biometricTimer = nil
    }

    private func streamBiometrics() async {
        guard let sessionId = currentSessionId else { return }
        struct BiometricPayload: Encodable {
            let sessionId: String
            let heartRate: Double
            let paceSecondsPerKm: Double
            let distanceKm: Double
            let elapsedSeconds: Int
        }
        let payload = BiometricPayload(
            sessionId: sessionId,
            heartRate: HealthKitService.shared.heartRate,
            paceSecondsPerKm: LocationService.shared.currentPaceSecondsPerKm,
            distanceKm: LocationService.shared.distanceKm,
            elapsedSeconds: WorkoutService.shared.elapsedSeconds
        )
        struct Empty: Decodable {}
        _ = try? await apiClient.post("/api/voice/biometrics", body: payload) as Empty
    }

    private func connectToDaily(roomURL: String, token: String) async {
        guard let url = URL(string: roomURL) else {
            sessionState = .error("Invalid room URL")
            return
        }
        let client = CallClient()
        client.delegate = self
        callClient = client
        do {
            try await client.join(url: url, token: .token(token))
            sessionState = .active
        } catch {
            sessionState = .error(error.localizedDescription)
        }
    }
}

extension VoiceSessionService: CallClientDelegate {
    func callClient(_ client: CallClient, participantUpdated participant: Participant) {
        agentSpeaking = participant.media?.audio?.state == .playable && !participant.info.isLocal
    }

    func callClient(_ client: CallClient, callStateUpdated state: CallState) {
        if state == .left || state == .error {
            sessionState = .idle
        }
    }
}
```

**Step 2: Commit**
```bash
git add PacePilot/PacePilot/Core/Services/VoiceSessionService.swift
git commit -m "feat: add VoiceSessionService for Daily.co WebRTC voice session lifecycle"
```

---

### Task 11: WatchConnectivityManager (iOS side)

**Files:**
- Create: `PacePilot/PacePilot/Core/Services/WatchConnectivityManager.swift`

```swift
// Core/Services/WatchConnectivityManager.swift
import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published private(set) var lastBiometricUpdate: BiometricUpdate?
    @Published private(set) var lastRunCommand: RunCommand?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func send(_ update: RunStateUpdate) {
        guard WCSession.default.isReachable else { return }
        if let data = try? encoder.encode(update) {
            WCSession.default.sendMessage(
                [WatchMessageType.runStateUpdate.rawValue: data],
                replyHandler: nil
            )
        }
    }

    func send(_ trigger: HapticTrigger) {
        guard WCSession.default.isReachable else { return }
        if let data = try? encoder.encode(trigger) {
            WCSession.default.sendMessage(
                [WatchMessageType.hapticTrigger.rawValue: data],
                replyHandler: nil
            )
        }
    }

    func send(_ sync: WorkoutSync) {
        guard WCSession.default.isReachable else { return }
        if let data = try? encoder.encode(sync) {
            WCSession.default.sendMessage(
                [WatchMessageType.workoutSync.rawValue: data],
                replyHandler: nil
            )
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[WatchMessageType.biometricUpdate.rawValue] as? Data,
           let update = try? decoder.decode(BiometricUpdate.self, from: data) {
            Task { @MainActor in self.lastBiometricUpdate = update }
        }
        if let data = message[WatchMessageType.runCommand.rawValue] as? Data,
           let cmd = try? decoder.decode(RunCommand.self, from: data) {
            Task { @MainActor in self.lastRunCommand = cmd }
        }
    }
}
```

**Step 2: Commit**
```bash
git add PacePilot/PacePilot/Core/Services/WatchConnectivityManager.swift
git commit -m "feat: add WatchConnectivityManager for bidirectional Watch/Phone messaging"
```

---

## Phase 5: Navigation Shell

### Task 12: AppRouter + Root Navigation

**Files:**
- Create: `PacePilot/PacePilot/App/AppRouter.swift`
- Modify: `PacePilot/PacePilot/PacePilotApp.swift`

**Step 1: Write AppRouter.swift**

```swift
// App/AppRouter.swift
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
```

**Step 2: Update PacePilotApp.swift**

```swift
// PacePilotApp.swift
import SwiftUI

@main
struct PacePilotApp: App {
    @StateObject private var router = AppRouter.shared
    @StateObject private var auth = AuthManager.shared
    @StateObject private var apiClient = APIClient.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(auth)
                .environmentObject(apiClient)
                .task { await auth.validateSession() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        switch router.route {
        case .splash:   SplashView()
        case .onboarding: OnboardingView()
        case .main:     MainTabView()
        }
    }
}

struct SplashView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Image(systemName: "figure.run")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                Text("PacePilot")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    auth.signInWithApple()
                }
                .frame(height: 50)
                .padding(.horizontal, 40)
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
            CommunityView()
                .tabItem { Label("Community", systemImage: "person.3.fill") }
            RaceDiscoveryView()
                .tabItem { Label("Races", systemImage: "flag.checkered") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .accentColor(.orange)
    }
}
```

**Step 3: Commit**
```bash
git add PacePilot/PacePilot/App/AppRouter.swift PacePilot/PacePilot/PacePilotApp.swift
git commit -m "feat: add AppRouter and root navigation shell with tab structure"
```

---

## Phase 6: Feature — Onboarding

### Task 13: Onboarding Voice UI

**Files:**
- Create: `PacePilot/PacePilot/Features/Onboarding/OnboardingView.swift`
- Create: `PacePilot/PacePilot/Features/Onboarding/WaveformView.swift`

**Step 1: Write WaveformView.swift**

```swift
// Features/Onboarding/WaveformView.swift
import SwiftUI

struct WaveformView: View {
    var isActive: Bool
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2
                let amplitude: Double = isActive ? 30 : 8
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midY))
                for x in stride(from: 0, through: width, by: 2) {
                    let relX = x / width
                    let y = midY + amplitude * sin(relX * 4 * .pi + phase)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(path, with: .color(.orange), lineWidth: 3)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .onChange(of: isActive) { _, _ in phase = 0 }
    }
}
```

**Step 2: Write OnboardingView.swift**

```swift
// Features/Onboarding/OnboardingView.swift
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var sessionState: VoiceSessionState = .idle
    @Published var agentSpeaking = false

    private let voice = VoiceSessionService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        voice.$sessionState.assign(to: &$sessionState)
        voice.$agentSpeaking.assign(to: &$agentSpeaking)
    }

    func startOnboarding() async {
        await voice.startSession(type: .onboarding)
    }

    func endOnboarding() async {
        await voice.endSession()
    }
}

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 48) {
                Spacer()
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                Text("Meet Your Coach")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("Tap below and say hello — your AI running coach is ready to learn about you.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                WaveformView(isActive: vm.agentSpeaking)
                    .frame(height: 60)
                    .padding(.horizontal, 32)
                statusText
                actionButton
                Spacer()
            }
        }
    }

    @ViewBuilder
    var statusText: some View {
        switch vm.sessionState {
        case .idle:
            Text("Tap to start").foregroundColor(.gray)
        case .connecting:
            Text("Connecting...").foregroundColor(.orange)
        case .active:
            Text(vm.agentSpeaking ? "Coach is speaking..." : "Listening...").foregroundColor(.green)
        case .disconnecting:
            Text("Finishing up...").foregroundColor(.gray)
        case .error(let msg):
            Text("Error: \(msg)").foregroundColor(.red).font(.caption)
        }
    }

    @ViewBuilder
    var actionButton: some View {
        switch vm.sessionState {
        case .idle, .error:
            Button(action: { Task { await vm.startOnboarding() } }) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "mic.fill").font(.title).foregroundColor(.white))
            }
        case .active:
            Button(action: { Task { await vm.endOnboarding() } }) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "stop.fill").font(.title).foregroundColor(.white))
            }
        default:
            ProgressView().tint(.orange)
        }
    }
}
```

**Step 3: Commit**
```bash
git add PacePilot/PacePilot/Features/Onboarding/
git commit -m "feat: add OnboardingView with voice session UI and animated waveform"
```

---

## Phase 7: Feature — Home

### Task 14: HomeView

**Files:**
- Create: `PacePilot/PacePilot/Features/Home/HomeView.swift`
- Create: `PacePilot/PacePilot/Features/Home/HomeViewModel.swift`

**Step 1: Write HomeViewModel.swift**

```swift
// Features/Home/HomeViewModel.swift
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todaysWorkout: Workout?
    @Published var weeklyDistanceKm: Double = 0
    @Published var weeklyRuns: Int = 0
    @Published var isLoading = false
    @Published var error: String?

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            todaysWorkout = try await api.get("/api/workouts/today")
        } catch {
            self.error = error.localizedDescription
        }
        do {
            struct Stats: Decodable { let weeklyDistanceKm: Double; let weeklyRuns: Int }
            let stats: Stats = try await api.get("/api/users/me/stats")
            weeklyDistanceKm = stats.weeklyDistanceKm
            weeklyRuns = stats.weeklyRuns
        } catch {}
    }
}
```

**Step 2: Write HomeView.swift**

```swift
// Features/Home/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showActiveRun = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weeklyStatsCard
                    if let workout = vm.todaysWorkout {
                        todaysWorkoutCard(workout)
                    } else if !vm.isLoading {
                        restDayCard
                    }
                    startRunButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PacePilot")
            .task { await vm.load() }
            .fullScreenCover(isPresented: $showActiveRun) {
                ActiveRunView()
            }
        }
    }

    var weeklyStatsCard: some View {
        HStack(spacing: 0) {
            statItem(value: String(format: "%.1f", vm.weeklyDistanceKm), label: "km this week")
            Divider().frame(height: 40)
            statItem(value: "\(vm.weeklyRuns)", label: "runs")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    func statItem(value: String, label: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    func todaysWorkoutCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Workout", systemImage: "calendar.badge.clock")
                .font(.headline)
            Text(workout.type.rawValue.capitalized)
                .font(.title3.bold())
            HStack {
                Label(String(format: "%.1f km", workout.targetDistanceKm), systemImage: "ruler")
                Spacer()
                Label(workout.targetPaceZone, systemImage: "speedometer")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    var restDayCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz").font(.largeTitle).foregroundColor(.blue)
            Text("Rest Day").font(.headline)
            Text("Recovery is part of training.").font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    var startRunButton: some View {
        Button(action: { showActiveRun = true }) {
            Label("Start Run", systemImage: "figure.run")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(16)
        }
    }
}
```

**Step 3: Commit**
```bash
git add PacePilot/PacePilot/Features/Home/
git commit -m "feat: add HomeView with today's workout card and weekly stats"
```

---

## Phase 8: Feature — Active Run

### Task 15: ActiveRunView

**Files:**
- Create: `PacePilot/PacePilot/Features/ActiveRun/ActiveRunViewModel.swift`
- Create: `PacePilot/PacePilot/Features/ActiveRun/ActiveRunView.swift`

**Step 1: Write ActiveRunViewModel.swift**

```swift
// Features/ActiveRun/ActiveRunViewModel.swift
import Foundation
import Combine

@MainActor
final class ActiveRunViewModel: ObservableObject {
    @Published var pace: String = "--:--"
    @Published var distanceKm: Double = 0
    @Published var elapsedSeconds: Int = 0
    @Published var heartRate: Double = 0
    @Published var agentSpeaking = false
    @Published var isRunning = false
    @Published var error: String?

    private let voice = VoiceSessionService.shared
    private let health = HealthKitService.shared
    private let location = LocationService.shared
    private let workout = WorkoutService.shared
    private let watch = WatchConnectivityManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        location.$currentPaceSecondsPerKm
            .map { PaceFormatter.format(secondsPerKm: $0) }
            .assign(to: &$pace)
        location.$distanceKm.assign(to: &$distanceKm)
        workout.$elapsedSeconds.assign(to: &$elapsedSeconds)
        health.$heartRate.assign(to: &$heartRate)
        voice.$agentSpeaking.assign(to: &$agentSpeaking)

        // Forward state to Watch
        Publishers.CombineLatest3(location.$distanceKm, workout.$elapsedSeconds, location.$currentPaceSecondsPerKm)
            .sink { [weak self] dist, elapsed, pace in
                guard let self, self.isRunning else { return }
                let update = RunStateUpdate(distanceKm: dist, elapsedSeconds: elapsed, paceSecondsPerKm: pace, isActive: true)
                self.watch.send(update)
            }
            .store(in: &cancellables)
    }

    func startRun() async {
        do {
            try await health.requestAuthorization()
            try await workout.startWorkout()
            location.startTracking()
            health.startHeartRateUpdates()
            await voice.startSession(type: .activeRun)
            voice.startBiometricStreaming()
            isRunning = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stopRun() async -> NewRunRequest? {
        isRunning = false
        voice.stopBiometricStreaming()
        await voice.endSession()
        health.stopHeartRateUpdates()
        location.stopTracking()
        _ = try? await workout.endWorkout()

        watch.send(RunStateUpdate(distanceKm: location.distanceKm, elapsedSeconds: workout.elapsedSeconds, paceSecondsPerKm: location.currentPaceSecondsPerKm, isActive: false))

        return NewRunRequest(
            workoutId: nil,
            startedAt: Date().addingTimeInterval(-Double(workout.elapsedSeconds)),
            endedAt: Date(),
            distanceKm: location.distanceKm,
            durationSeconds: workout.elapsedSeconds,
            avgPaceSecondsPerKm: location.currentPaceSecondsPerKm,
            avgHeartRate: Int(health.heartRate),
            maxHeartRate: Int(health.heartRate),
            calories: Int(workout.calories),
            elevationGainMeters: workout.elevationGain,
            splits: [],
            gpsTrack: location.gpsTrack
        )
    }
}
```

**Step 2: Write ActiveRunView.swift**

```swift
// Features/ActiveRun/ActiveRunView.swift
import SwiftUI

struct ActiveRunView: View {
    @StateObject private var vm = ActiveRunViewModel()
    @State private var runResult: NewRunRequest?
    @State private var showPostRun = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if vm.isRunning {
                runningMetrics
            } else {
                startPrompt
            }
        }
        .statusBarHidden()
        .task { await vm.startRun() }
        .fullScreenCover(isPresented: $showPostRun) {
            if let result = runResult {
                PostRunView(runRequest: result)
            }
        }
    }

    var startPrompt: some View {
        VStack(spacing: 24) {
            ProgressView().tint(.orange).scaleEffect(1.5)
            Text("Getting ready...").foregroundColor(.white)
        }
    }

    var runningMetrics: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { Task {
                    runResult = await vm.stopRun()
                    showPostRun = true
                }}) {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
                if vm.agentSpeaking {
                    Label("Coach", systemImage: "waveform")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
            Spacer()

            // Main metrics
            VStack(spacing: 24) {
                metricBlock(value: vm.pace, label: "PACE /km")
                HStack(spacing: 40) {
                    metricBlock(value: String(format: "%.2f", vm.distanceKm), label: "KM")
                    metricBlock(value: RunTimeFormatter.format(seconds: vm.elapsedSeconds), label: "TIME")
                }
                metricBlock(value: vm.heartRate > 0 ? "\(Int(vm.heartRate))" : "--", label: "BPM")
            }

            Spacer()
            if vm.agentSpeaking {
                WaveformView(isActive: true)
                    .frame(height: 40)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }

    func metricBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
```

**Step 3: Commit**
```bash
git add PacePilot/PacePilot/Features/ActiveRun/
git commit -m "feat: add ActiveRunView with live biometric metrics and voice coaching overlay"
```

---

## Phase 9: Feature — Post Run

### Task 16: PostRunView

**Files:**
- Create: `PacePilot/PacePilot/Features/PostRun/PostRunViewModel.swift`
- Create: `PacePilot/PacePilot/Features/PostRun/PostRunView.swift`

**Step 1: Write PostRunViewModel.swift**

```swift
// Features/PostRun/PostRunViewModel.swift
import Foundation

@MainActor
final class PostRunViewModel: ObservableObject {
    @Published var savedSession: RunSession?
    @Published var isSaving = false
    @Published var agentSpeaking = false
    @Published var error: String?

    private let api: APIClient
    private let voice = VoiceSessionService.shared

    init(api: APIClient = .shared) {
        self.api = api
        voice.$agentSpeaking.assign(to: &$agentSpeaking)
    }

    func saveAndDebrief(run: NewRunRequest) async {
        isSaving = true
        do {
            savedSession = try await api.post("/api/runs", body: run)
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
        await voice.startSession(type: .postRun)
    }

    func finish() async {
        await voice.endSession()
    }
}
```

**Step 2: Write PostRunView.swift**

```swift
// Features/PostRun/PostRunView.swift
import SwiftUI
import MapKit

struct PostRunView: View {
    let runRequest: NewRunRequest
    @StateObject private var vm = PostRunViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.agentSpeaking {
                        debriefBanner
                    }
                    summaryCard
                    if !runRequest.gpsTrack.isEmpty {
                        mapCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Run Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { Task { await vm.finish(); dismiss() } }
                }
            }
            .task { await vm.saveAndDebrief(run: runRequest) }
        }
    }

    var debriefBanner: some View {
        HStack {
            Image(systemName: "waveform").foregroundColor(.orange)
            Text("Coach debrief in progress...")
                .font(.subheadline)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    var summaryCard: some View {
        VStack(spacing: 16) {
            Text("Summary").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statCell(value: String(format: "%.2f km", runRequest.distanceKm), label: "Distance")
                statCell(value: RunTimeFormatter.format(seconds: runRequest.durationSeconds), label: "Duration")
                statCell(value: PaceFormatter.format(secondsPerKm: runRequest.avgPaceSecondsPerKm) + "/km", label: "Avg Pace")
                statCell(value: "\(runRequest.avgHeartRate) bpm", label: "Avg HR")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }

    var mapCard: some View {
        let coords = runRequest.gpsTrack.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let region = MKCoordinateRegion(
            center: coords.first ?? CLLocationCoordinate2D(),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        return Map(initialPosition: .region(region)) {
            MapPolyline(coordinates: coords)
                .stroke(.orange, lineWidth: 3)
        }
        .frame(height: 200)
        .cornerRadius(16)
    }
}
```

**Step 3: Commit**
```bash
git add PacePilot/PacePilot/Features/PostRun/
git commit -m "feat: add PostRunView with summary stats, map route, and agent debrief"
```

---

## Phase 10: Remaining Features (Plan, Community, Races, History, Profile)

### Task 17: PlanView

**Files:**
- Create: `PacePilot/PacePilot/Features/Plan/PlanViewModel.swift`
- Create: `PacePilot/PacePilot/Features/Plan/PlanView.swift`

```swift
// Features/Plan/PlanViewModel.swift
import Foundation

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var plan: TrainingPlan?
    @Published var workouts: [Workout] = []
    @Published var selectedWorkout: Workout?
    @Published var isLoading = false

    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            plan = try await api.get("/api/plans/active")
            if let id = plan?.id {
                workouts = try await api.get("/api/plans/\(id)/workouts")
            }
        } catch {}
    }

    func skipWorkout(_ id: String) async {
        struct Empty: Decodable {}
        _ = try? await api.patch("/api/workouts/\(id)/skip", body: EmptyBody()) as Empty
        await load()
    }

    struct EmptyBody: Encodable {}
}
```

```swift
// Features/Plan/PlanView.swift
import SwiftUI

struct PlanView: View {
    @StateObject private var vm = PlanViewModel()
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(.orange)
                    .padding(.horizontal)
                workoutsForSelectedDate
            }
            .navigationTitle("Training Plan")
            .task { await vm.load() }
        }
    }

    var workoutsForSelectedDate: some View {
        let dayWorkouts = vm.workouts.filter {
            Calendar.current.isDate($0.scheduledDate, inSameDayAs: selectedDate)
        }
        return List(dayWorkouts) { workout in
            VStack(alignment: .leading, spacing: 6) {
                Text(workout.type.rawValue.capitalized).font(.headline)
                Text(String(format: "%.1f km · %@", workout.targetDistanceKm, workout.targetPaceZone))
                    .font(.caption).foregroundColor(.secondary)
            }
            .swipeActions {
                Button("Skip", role: .destructive) { Task { await vm.skipWorkout(workout.id) } }
            }
        }
        .listStyle(.insetGrouped)
    }
}
```

**Step 3: Commit**
```bash
git add PacePilot/PacePilot/Features/Plan/
git commit -m "feat: add PlanView with calendar and workout list"
```

---

### Task 18: CommunityView

```swift
// Features/Community/CommunityViewModel.swift
import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var community: Community?
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var friendActivity: [FriendActivity] = []
    @Published var isLoading = false

    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let communityResult: Community = (try? api.get("/api/communities/me")) ?? Community(id: "", tier: .momentum, name: "", memberCount: 0, challenges: [])
        async let leaderboardResult: [LeaderboardEntry] = (try? api.get("/api/communities/me/leaderboard")) ?? []
        async let activityResult: [FriendActivity] = (try? api.get("/api/communities/friends/activity")) ?? []
        (community, leaderboard, friendActivity) = await (communityResult, leaderboardResult, activityResult)
    }
}
```

```swift
// Features/Community/CommunityView.swift
import SwiftUI

struct CommunityView: View {
    @StateObject private var vm = CommunityViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let community = vm.community {
                    Section("Your Tier") {
                        HStack {
                            tierBadge(community.tier)
                            VStack(alignment: .leading) {
                                Text(community.name).font(.headline)
                                Text("\(community.memberCount) runners").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                Section("This Week's Leaderboard") {
                    ForEach(vm.leaderboard) { entry in
                        HStack {
                            Text("#\(entry.rank)").font(.headline).foregroundColor(.orange).frame(width: 36)
                            Text(entry.displayName)
                            Spacer()
                            Text(String(format: "%.1f km", entry.weeklyDistanceKm)).foregroundColor(.secondary)
                        }
                    }
                }
                Section("Friend Activity") {
                    ForEach(vm.friendActivity) { activity in
                        VStack(alignment: .leading) {
                            Text(activity.displayName).font(.headline)
                            Text(String(format: "%.1f km · %@/km", activity.distanceKm, PaceFormatter.format(secondsPerKm: activity.paceSecondsPerKm)))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Community")
            .task { await vm.load() }
        }
    }

    func tierBadge(_ tier: User.CommunityTier) -> some View {
        let colors: [User.CommunityTier: Color] = [
            .discovery: .gray, .foundation: .blue, .momentum: .green, .velocity: .orange, .elite: .purple
        ]
        return Text(tier.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(colors[tier, default: .gray].opacity(0.2))
            .foregroundColor(colors[tier, default: .gray])
            .cornerRadius(8)
    }
}
```

**Commit:**
```bash
git add PacePilot/PacePilot/Features/Community/
git commit -m "feat: add CommunityView with tier badge, leaderboard, and friend activity"
```

---

### Task 19: RaceDiscoveryView

```swift
// Features/Races/RacesViewModel.swift
import Foundation

@MainActor
final class RacesViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var isLoading = false
    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        races = (try? await api.get("/api/races/discover")) ?? []
        isLoading = false
    }

    func markInterest(_ raceId: String) async {
        struct Empty: Decodable {}
        struct EmptyBody: Encodable {}
        _ = try? await api.post("/api/races/\(raceId)/register-interest", body: EmptyBody()) as Empty
        if let idx = races.firstIndex(where: { $0.id == raceId }) {
            races[idx].isInterestedByUser = true
        }
    }
}
```

```swift
// Features/Races/RaceDiscoveryView.swift
import SwiftUI

struct RaceDiscoveryView: View {
    @StateObject private var vm = RacesViewModel()

    var body: some View {
        NavigationStack {
            List(vm.races) { race in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(race.name).font(.headline)
                        Spacer()
                        if race.isInterestedByUser {
                            Image(systemName: "star.fill").foregroundColor(.orange)
                        }
                    }
                    HStack(spacing: 12) {
                        Label(String(format: "%.0f km", race.distanceKm), systemImage: "ruler")
                        Label(race.location, systemImage: "mappin")
                        Label(race.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                    .font(.caption).foregroundColor(.secondary)
                }
                .swipeActions {
                    if !race.isInterestedByUser {
                        Button("Interested") { Task { await vm.markInterest(race.id) } }
                            .tint(.orange)
                    }
                }
            }
            .navigationTitle("Races")
            .task { await vm.load() }
        }
    }
}
```

**Commit:**
```bash
git add PacePilot/PacePilot/Features/Races/
git commit -m "feat: add RaceDiscoveryView with interest marking"
```

---

### Task 20: HistoryView

```swift
// Features/History/HistoryViewModel.swift
import Foundation

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
```

```swift
// Features/History/RunHistoryView.swift
import SwiftUI

struct RunHistoryView: View {
    @StateObject private var vm = HistoryViewModel()

    var body: some View {
        NavigationStack {
            List(vm.runs) { run in
                NavigationLink(destination: RunDetailView(run: run)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(run.startedAt.formatted(date: .abbreviated, time: .shortened)).font(.headline)
                        HStack(spacing: 16) {
                            Label(String(format: "%.2f km", run.distanceKm), systemImage: "ruler")
                            Label(RunTimeFormatter.format(seconds: run.durationSeconds), systemImage: "clock")
                            Label(PaceFormatter.format(secondsPerKm: run.avgPaceSecondsPerKm) + "/km", systemImage: "speedometer")
                        }
                        .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("History")
            .task { await vm.load() }
        }
    }
}

struct RunDetailView: View {
    let run: RunSession

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryGrid
                splitsSection
            }
            .padding()
        }
        .navigationTitle(run.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCell(value: String(format: "%.2f km", run.distanceKm), label: "Distance")
            statCell(value: RunTimeFormatter.format(seconds: run.durationSeconds), label: "Duration")
            statCell(value: PaceFormatter.format(secondsPerKm: run.avgPaceSecondsPerKm) + "/km", label: "Avg Pace")
            statCell(value: "\(run.avgHeartRate) bpm", label: "Avg HR")
            statCell(value: "\(run.calories) kcal", label: "Calories")
            statCell(value: String(format: "%.0f m", run.elevationGainMeters), label: "Elevation")
        }
    }

    func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Splits").font(.headline)
            ForEach(run.splits, id: \.kmNumber) { split in
                HStack {
                    Text("KM \(split.kmNumber)").font(.subheadline)
                    Spacer()
                    Text(PaceFormatter.format(secondsPerKm: split.paceSecondsPerKm) + "/km")
                    Text("\(split.avgHeartRate) bpm").foregroundColor(.secondary)
                }
                .font(.caption)
                Divider()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
```

**Commit:**
```bash
git add PacePilot/PacePilot/Features/History/
git commit -m "feat: add RunHistoryView and RunDetailView with splits"
```

---

### Task 21: ProfileView

```swift
// Features/Profile/ProfileViewModel.swift
import Foundation

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
```

```swift
// Features/Profile/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let user = vm.user {
                    Section("Account") {
                        LabeledContent("Name", value: user.displayName)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Community Tier", value: user.communityTier.rawValue.capitalized)
                    }
                }
                Section("Connected Services") {
                    Button(action: { Task { await vm.connectStrava() } }) {
                        Label("Connect Strava", systemImage: "link")
                    }
                    .disabled(vm.user?.stravaConnected == true)
                }
                Section {
                    Button("Sign Out", role: .destructive) { vm.signOut() }
                }
            }
            .navigationTitle("Profile")
            .task { await vm.load() }
        }
    }
}
```

**Commit:**
```bash
git add PacePilot/PacePilot/Features/Profile/
git commit -m "feat: add ProfileView with connected services and sign out"
```

---

## Phase 11: Apple Watch App

### Task 22: Watch Services

**Files:**
- Create: `PacePilot/PacePilotWatch Watch App/Services/WatchWorkoutManager.swift`
- Create: `PacePilot/PacePilotWatch Watch App/Services/WatchConnectivityManager.swift`
- Create: `PacePilot/PacePilotWatch Watch App/Services/WatchHapticManager.swift`

```swift
// PacePilotWatch Watch App/Services/WatchConnectivityManager.swift
import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var runState: RunStateUpdate?
    @Published var hapticTrigger: HapticTrigger?
    @Published var workoutSync: WorkoutSync?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendBiometricUpdate(_ update: BiometricUpdate) {
        guard WCSession.default.isReachable,
              let data = try? encoder.encode(update) else { return }
        WCSession.default.sendMessage([WatchMessageType.biometricUpdate.rawValue: data], replyHandler: nil)
    }

    func sendRunCommand(_ command: RunCommand) {
        guard WCSession.default.isReachable,
              let data = try? encoder.encode(command) else { return }
        WCSession.default.sendMessage([WatchMessageType.runCommand.rawValue: data], replyHandler: nil)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[WatchMessageType.runStateUpdate.rawValue] as? Data,
           let update = try? decoder.decode(RunStateUpdate.self, from: data) {
            Task { @MainActor in self.runState = update }
        }
        if let data = message[WatchMessageType.hapticTrigger.rawValue] as? Data,
           let trigger = try? decoder.decode(HapticTrigger.self, from: data) {
            Task { @MainActor in self.hapticTrigger = trigger }
        }
        if let data = message[WatchMessageType.workoutSync.rawValue] as? Data,
           let sync = try? decoder.decode(WorkoutSync.self, from: data) {
            Task { @MainActor in self.workoutSync = sync }
        }
    }
}
```

```swift
// PacePilotWatch Watch App/Services/WatchHapticManager.swift
import WatchKit

enum WatchHapticManager {
    static func play(_ type: HapticTrigger.HapticType) {
        let hapticType: WKHapticType
        switch type {
        case .intervalStart: hapticType = .start
        case .intervalEnd: hapticType = .stop
        case .milestone: hapticType = .success
        case .paceAlert, .heartRateAlert: hapticType = .directionUp
        }
        WKInterfaceDevice.current().play(hapticType)
    }
}
```

**Commit:**
```bash
git add "PacePilot/PacePilotWatch Watch App/Services/"
git commit -m "feat: add Watch connectivity and haptic managers"
```

---

### Task 23: Watch Views

**Files:**
- Create: `PacePilot/PacePilotWatch Watch App/Views/WatchHomeView.swift`
- Create: `PacePilot/PacePilotWatch Watch App/Views/WatchActiveRunView.swift`
- Modify: `PacePilot/PacePilotWatch Watch App/PacePilotWatchApp.swift`

```swift
// PacePilotWatch Watch App/Views/WatchHomeView.swift
import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showActiveRun = false

    var body: some View {
        VStack(spacing: 12) {
            if let sync = connectivity.workoutSync {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today").font(.caption2).foregroundColor(.orange)
                    Text(sync.workoutType.capitalized).font(.headline)
                    Text(String(format: "%.1f km", sync.targetDistanceKm)).font(.caption)
                }
            } else {
                Text("No workout today").font(.caption).foregroundColor(.secondary)
            }
            Button(action: {
                connectivity.sendRunCommand(RunCommand(command: .start))
                showActiveRun = true
            }) {
                Label("Start", systemImage: "figure.run")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .navigationDestination(isPresented: $showActiveRun) {
            WatchActiveRunView()
        }
    }
}
```

```swift
// PacePilotWatch Watch App/Views/WatchActiveRunView.swift
import SwiftUI

struct WatchActiveRunView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 8) {
            if let state = connectivity.runState {
                metricRow(value: RunTimeFormatter.format(seconds: state.elapsedSeconds), label: "TIME")
                metricRow(value: String(format: "%.2f", state.distanceKm), label: "KM")
                metricRow(value: PaceFormatter.format(secondsPerKm: state.paceSecondsPerKm), label: "/KM")
            } else {
                ProgressView()
            }
            Button(action: {
                connectivity.sendRunCommand(RunCommand(command: .stop))
            }) {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .onChange(of: connectivity.hapticTrigger) { _, trigger in
            if let trigger { WatchHapticManager.play(trigger.type) }
        }
    }

    func metricRow(value: String, label: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(.body, design: .monospaced).bold())
        }
    }
}
```

```swift
// PacePilotWatchApp.swift
import SwiftUI

@main
struct PacePilotWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
                    .navigationTitle("PacePilot")
            }
            .environmentObject(connectivity)
        }
    }
}
```

**Commit:**
```bash
git add "PacePilot/PacePilotWatch Watch App/Views/" "PacePilot/PacePilotWatch Watch App/PacePilotWatchApp.swift"
git commit -m "feat: add WatchHomeView and WatchActiveRunView with live metrics"
```

---

## Phase 12: Final Wiring

### Task 24: Move ContentView → delete, connect Shared module

**Step 1: Delete original ContentView**

Remove `ContentView.swift` from the iOS target (in Xcode) — it is replaced by `PacePilotApp.swift` / `AppRouter`.

**Step 2: Update Shared/Shared.swift to re-export WatchMessage types**

```swift
// Shared/Shared.swift
// WatchMessage types are defined in Shared/WatchMessage.swift (already added above)
// This file is intentionally minimal — the Shared target exposes WatchMessage.swift
```

**Step 3: Add Shared target to both iOS and Watch targets in Xcode**

In Xcode, select `Shared.swift` and `WatchMessage.swift` → File Inspector → Target Membership → check both `PacePilot` and `PacePilotWatch Watch App`.

**Step 4: Final build check**
```bash
xcodebuild build -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|BUILD|FAILED|SUCCEEDED)"
```
Expected: `BUILD SUCCEEDED`

**Step 5: Commit**
```bash
git add -A
git commit -m "feat: complete iOS + Watch app implementation — all layers wired"
```

---

## Summary

| Phase | Tasks | What Gets Built |
|-------|-------|----------------|
| 1 | 1–2 | Xcode setup, Daily SDK, directory structure |
| 2 | 3–4 | Utilities, all data models |
| 3 | 5–6 | APIClient, AuthManager |
| 4 | 7–11 | HealthKit, Location, Workout, Voice, Watch services |
| 5 | 12 | AppRouter, root navigation, tab bar |
| 6–10 | 13–21 | All 9 feature screens |
| 11 | 22–23 | Watch app views and services |
| 12 | 24 | Final wiring, build verification |
