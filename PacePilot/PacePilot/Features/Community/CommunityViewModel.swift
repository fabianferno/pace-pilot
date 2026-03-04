import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var community: Community?
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var friendActivity: [FriendActivity] = []
    @Published var isLoading = false

    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let communityResult: Community = (try? api.get("/api/communities/me")) ?? Community(id: "", tier: .momentum, name: "", memberCount: 0, challenges: [])
        async let leaderboardResult: [LeaderboardEntry] = (try? api.get("/api/communities/me/leaderboard")) ?? []
        async let activityResult: [FriendActivity] = (try? api.get("/api/communities/friends/activity")) ?? []
        (community, leaderboard, friendActivity) = await (communityResult, leaderboardResult, activityResult)
    }
}
