import SwiftUI

@main
struct PacePilotWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
                    .navigationTitle("PacePilot")
            }
            .environmentObject(connectivity)
        }
    }
}
