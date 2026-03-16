import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @EnvironmentObject var workout: WatchWorkoutManager
    @State private var showActiveRun = false

    var body: some View {
        VStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56) // Increased from 36x36 to make the logo bigger
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            if let sync = connectivity.workoutSync {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today").font(.caption2).foregroundColor(.brand)
                    Text(sync.workoutType.capitalized).font(.headline)
                    Text(String(format: "%.1f km", sync.targetDistanceKm)).font(.caption)
                }
            } else {
                Text("No workout today").font(.caption).foregroundColor(.secondary)
            }
            Button(action: {
                connectivity.sendRunCommand(RunCommand(command: .start))
                Task { try? await workout.startWorkout() }
                showActiveRun = true
            }) {
                Label("Start", systemImage: "figure.run").foregroundColor(.black)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brand)
        }
        .navigationDestination(isPresented: $showActiveRun) {
            WatchActiveRunView()
        }
    }
}
