import Foundation

struct CommunityRun: Codable, Identifiable {
    let id: String
    let name: String
    let distanceKm: Double
    let date: Date
    let location: String
    let city: String
    let latitude: Double
    let longitude: Double
    var rsvpCount: Int
    var isRsvpdByUser: Bool
}
