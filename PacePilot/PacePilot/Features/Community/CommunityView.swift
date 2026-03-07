import SwiftUI

struct CommunityView: View {
    @StateObject private var vm = CommunityViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    communityHeaderCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                howItWorksSection

                if let community = vm.community {
                    Section("Your Tier") {
                        HStack(spacing: 14) {
                            tierBadge(community.tier)
                            VStack(alignment: .leading, spacing: 3) {
                                if !community.name.isEmpty {
                                    Text(community.name).font(.headline)
                                }
                                Text("\(community.memberCount) runners")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("This Week's Leaderboard") {
                    if vm.leaderboard.isEmpty && !vm.isLoading {
                        emptySection(
                            icon: "trophy",
                            title: "No runs yet this week",
                            message: "Complete a run to appear on the leaderboard."
                        )
                    } else {
                        ForEach(vm.leaderboard) { entry in
                            HStack {
                                Text("#\(entry.rank)")
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36)
                                Text(entry.displayName)
                                Spacer()
                                Text(String(format: "%.1f km", entry.weeklyDistanceKm))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Friend Activity") {
                    if vm.friendActivity.isEmpty && !vm.isLoading {
                        emptySection(
                            icon: "person.2",
                            title: "No recent activity",
                            message: "Your friends' runs will show up here."
                        )
                    } else {
                        ForEach(vm.friendActivity) { activity in
                            VStack(alignment: .leading) {
                                Text(activity.displayName).font(.headline)
                                Text(String(format: "%.1f km · %@/km",
                                            activity.distanceKm,
                                            PaceFormatter.format(secondsPerKm: activity.paceSecondsPerKm)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Community")
            .task { await vm.load() }
        }
    }

    var communityHeaderCard: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.35)],
                startPoint: .leading,
                endPoint: .trailing
            )

            Image("RunnerFemale")
                .resizable()
                .scaledToFit()
                .frame(height: 145)
                .padding(.bottom, -4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Run Together")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Your community, your pace.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var howItWorksSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("How Community Works", systemImage: "info.circle")
                    .font(.subheadline.bold())
                    .foregroundColor(.accentColor)
                Text("You're automatically placed into a tier based on your average easy-run pace over the past 4 weeks. As you run more consistently, you move up through **Discovery → Foundation → Momentum → Velocity → Elite**. Tiers update every week.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }

    func emptySection(icon: String, title: String, message: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor.opacity(0.7))
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(message).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    func tierBadge(_ tier: User.CommunityTier) -> some View {
        let colors: [User.CommunityTier: Color] = [
            .discovery: .secondary,
            .foundation: .accentColor,
            .momentum: .accentColor,
            .velocity: .orange,
            .elite: .purple
        ]
        let color = colors[tier, default: .accentColor]
        return Text(tier.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}
