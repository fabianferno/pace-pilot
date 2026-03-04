import Foundation

struct Race: Codable, Identifiable {
    let id: String
    let name: String
    let distanceKm: Double
    let date: Date
    let location: String
    let registrationURL: String?
    let elevationGainMeters: Double?
    var isInterestedByUser: Bool
}
