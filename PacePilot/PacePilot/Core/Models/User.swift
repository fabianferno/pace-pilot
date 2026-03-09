import Foundation

struct User: Codable, Identifiable, Equatable {
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
    var restingHr: Int?
    var maxHr: Int?
    var preferredDays: [Int]
    var city: String?

    enum CommunityTier: String, Codable {
        case discovery, foundation, momentum, velocity, elite
    }

    enum CodingKeys: String, CodingKey {
        case id, email, displayName, communityTier, onboardingComplete
        case stravaConnected, googleCalendarConnected, weeklyMileageGoal
        case targetRaceDistance, targetRaceDate, restingHr, maxHr
        case preferredDays, city
    }

    init(
        id: String,
        email: String,
        displayName: String,
        communityTier: CommunityTier,
        onboardingComplete: Bool,
        stravaConnected: Bool,
        googleCalendarConnected: Bool,
        weeklyMileageGoal: Double? = nil,
        targetRaceDistance: String? = nil,
        targetRaceDate: Date? = nil,
        restingHr: Int? = nil,
        maxHr: Int? = nil,
        preferredDays: [Int] = [],
        city: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.communityTier = communityTier
        self.onboardingComplete = onboardingComplete
        self.stravaConnected = stravaConnected
        self.googleCalendarConnected = googleCalendarConnected
        self.weeklyMileageGoal = weeklyMileageGoal
        self.targetRaceDistance = targetRaceDistance
        self.targetRaceDate = targetRaceDate
        self.restingHr = restingHr
        self.maxHr = maxHr
        self.preferredDays = preferredDays
        self.city = city
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        email = try c.decode(String.self, forKey: .email)
        displayName = try c.decode(String.self, forKey: .displayName)
        communityTier = try c.decode(CommunityTier.self, forKey: .communityTier)
        onboardingComplete = try c.decode(Bool.self, forKey: .onboardingComplete)
        stravaConnected = try c.decode(Bool.self, forKey: .stravaConnected)
        googleCalendarConnected = try c.decode(Bool.self, forKey: .googleCalendarConnected)
        weeklyMileageGoal = try c.decodeIfPresent(Double.self, forKey: .weeklyMileageGoal)
        targetRaceDistance = try c.decodeIfPresent(String.self, forKey: .targetRaceDistance)
        targetRaceDate = try c.decodeIfPresent(Date.self, forKey: .targetRaceDate)
        restingHr = try c.decodeIfPresent(Int.self, forKey: .restingHr)
        maxHr = try c.decodeIfPresent(Int.self, forKey: .maxHr)
        preferredDays = try c.decodeIfPresent([Int].self, forKey: .preferredDays) ?? []
        city = try c.decodeIfPresent(String.self, forKey: .city)
    }
}
