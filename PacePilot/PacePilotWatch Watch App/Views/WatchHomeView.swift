import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showActiveRun = false

    var body: some View {
        VStack(spacing: 12) {
            if let sync = connectivity.workoutSync {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today").font(.caption2).foregroundColor(.orange)
                    Text(sync.workoutType.capitalized).font(.headline)
                    Text(String(format: "%.1f km", sync.targetDistanceKm)).font(.caption)
                }
            } else {
                Text("No workout today").font(.caption).foregroundColor(.secondary)
            }
            Button(action: {
                connectivity.sendRunCommand(RunCommand(command: .start))
                showActiveRun = true
            }) {
                Label("Start", systemImage: "figure.run")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .navigationDestination(isPresented: $showActiveRun) {
            WatchActiveRunView()
        }
    }
}
