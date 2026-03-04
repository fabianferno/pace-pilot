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
