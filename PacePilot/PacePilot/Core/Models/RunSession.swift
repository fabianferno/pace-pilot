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
