import Foundation
import Combine
#if canImport(Daily)
import Daily
#endif

enum VoiceSessionState: Equatable {
    case idle, connecting, active, disconnecting, error(String)
}

@MainActor
final class VoiceSessionService: NSObject, ObservableObject {
    static let shared = VoiceSessionService()

    @Published private(set) var sessionState: VoiceSessionState = .idle
    @Published private(set) var agentSpeaking = false
    @Published private(set) var botAudioReady = false

    private let apiClient: APIClient
#if canImport(Daily)
    private var callClient: CallClient?
#endif
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
        botAudioReady = false
        sessionState = .disconnecting
        stopBiometricStreaming()
#if canImport(Daily)
        try? await callClient?.leave()
#endif
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
#if canImport(Daily)
        guard let url = URL(string: roomURL) else {
            sessionState = .error("Invalid room URL")
            return
        }
        let client = CallClient()
        client.delegate = self
        callClient = client
        do {
            try await client.join(url: url, token: MeetingToken(stringValue: token))
            sessionState = .active
        } catch {
            sessionState = .error(error.localizedDescription)
        }
#else
        sessionState = .error("Daily SDK not available — add SPM package")
#endif
    }
}

#if canImport(Daily)
extension VoiceSessionService: CallClientDelegate {
    func callClient(_ client: CallClient, participantUpdated participant: Participant) {
        guard !participant.info.isLocal else { return }
        let audioPlayable = participant.media?.microphone.state == .playable
        agentSpeaking = audioPlayable
        if audioPlayable { botAudioReady = true }
    }

    func callClient(_ client: CallClient, callStateUpdated state: CallState) {
        if state == .left {
            sessionState = .idle
        }
    }
}
#endif
