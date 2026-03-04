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
