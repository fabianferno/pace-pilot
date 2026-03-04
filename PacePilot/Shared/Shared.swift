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
