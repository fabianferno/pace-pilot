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

struct HapticTrigger: Codable, Equatable {
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

// MARK: - Formatters (shared between iOS and watchOS)

enum PaceFormatter {
    static func format(secondsPerKm: Double) -> String {
        let total = Int(secondsPerKm)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func fromMetersPerSecond(_ mps: Double) -> String {
        guard mps > 0 else { return "--:--" }
        let secondsPerKm = 1000.0 / mps
        return format(secondsPerKm: secondsPerKm)
    }
}

enum RunTimeFormatter {
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
