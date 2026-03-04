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
