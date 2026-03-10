import Foundation
import Combine

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
            if let session = savedSession {
                NotificationService.shared.sendPostRunCelebration(session: session)
            }
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
