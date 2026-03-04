import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let user = vm.user {
                    Section("Account") {
                        LabeledContent("Name", value: user.displayName)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Community Tier", value: user.communityTier.rawValue.capitalized)
                    }
                }
                Section("Connected Services") {
                    Button(action: { Task { await vm.connectStrava() } }) {
                        Label("Connect Strava", systemImage: "link")
                    }
                    .disabled(vm.user?.stravaConnected == true)
                }
                Section {
                    Button("Sign Out", role: .destructive) { vm.signOut() }
                }
            }
            .navigationTitle("Profile")
            .task { await vm.load() }
        }
    }
}
