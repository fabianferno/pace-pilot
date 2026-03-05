import SwiftUI

struct CommunityView: View {
    @StateObject private var vm = CommunityViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let community = vm.community {
                    Section("Your Tier") {
                        HStack {
                            tierBadge(community.tier)
                            VStack(alignment: .leading) {
                                Text(community.name).font(.headline)
                                Text("\(community.memberCount) runners").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                Section("This Week's Leaderboard") {
                    ForEach(vm.leaderboard) { entry in
                        HStack {
                            Text("#\(entry.rank)").font(.headline).foregroundColor(.accentColor).frame(width: 36)
                            Text(entry.displayName)
                            Spacer()
                            Text(String(format: "%.1f km", entry.weeklyDistanceKm)).foregroundColor(.secondary)
                        }
                    }
                }
                Section("Friend Activity") {
                    ForEach(vm.friendActivity) { activity in
                        VStack(alignment: .leading) {
                            Text(activity.displayName).font(.headline)
                            Text(String(format: "%.1f km · %@/km", activity.distanceKm, PaceFormatter.format(secondsPerKm: activity.paceSecondsPerKm)))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Community")
            .task { await vm.load() }
        }
    }

    func tierBadge(_ tier: User.CommunityTier) -> some View {
        let colors: [User.CommunityTier: Color] = [
            .discovery: .gray, .foundation: .blue, .momentum: .green, .velocity: .orange, .elite: .purple
        ]
        return Text(tier.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(colors[tier, default: .gray].opacity(0.2))
            .foregroundColor(colors[tier, default: .gray])
            .cornerRadius(8)
    }
}
