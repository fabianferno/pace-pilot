import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var displayName: String
    var communityTier: CommunityTier
    var onboardingComplete: Bool
    var stravaConnected: Bool
    var googleCalendarConnected: Bool
    var weeklyMileageGoal: Double?
    var targetRaceDistance: String?
    var targetRaceDate: Date?

    enum CommunityTier: String, Codable {
        case discovery, foundation, momentum, velocity, elite
    }
}
