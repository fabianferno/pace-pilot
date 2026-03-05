import Foundation

struct TrainingPlan: Codable, Identifiable {
    let id: String
    let userId: String
    let startDate: Date
    let endDate: Date
    let phase: Phase
    let paceZones: PaceZones
    let hrZones: HRZones?
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
