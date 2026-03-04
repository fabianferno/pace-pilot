import Foundation

struct Community: Codable, Identifiable {
    let id: String
    let tier: User.CommunityTier
    let name: String
    let memberCount: Int
    let challenges: [Challenge]
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let weeklyDistanceKm: Double
    let rank: Int
}

struct Challenge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let targetKm: Double
    let endDate: Date
}

struct FriendActivity: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let distanceKm: Double
    let paceSecondsPerKm: Double
    let completedAt: Date
}
