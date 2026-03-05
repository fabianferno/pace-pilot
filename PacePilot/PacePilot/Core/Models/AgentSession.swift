import Foundation

struct AgentSession: Codable, Identifiable {
    let id: String
    let userId: String
    let sessionType: SessionType
    let startedAt: Date
    let endedAt: Date?
    let transcript: [TranscriptEntry]

    enum SessionType: String, Codable {
        case onboarding, preRun = "pre_run", activeRun = "active_run", postRun = "post_run", general, replan
    }

    struct TranscriptEntry: Codable, Identifiable {
        let id: String
        let role: String  // "agent" | "user"
        let content: String
        let timestamp: Date
    }
}
