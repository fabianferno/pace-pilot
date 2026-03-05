import SwiftUI

struct WatchActiveRunView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @EnvironmentObject var workout: WatchWorkoutManager

    var body: some View {
        VStack(spacing: 8) {
            metricRow(value: RunTimeFormatter.format(seconds: workout.elapsedSeconds), label: "TIME")
            metricRow(value: String(format: "%.2f", workout.distanceKm), label: "KM")
            metricRow(value: workout.pace > 0 ? PaceFormatter.format(secondsPerKm: workout.pace) : "--:--", label: "/KM")
            metricRow(value: workout.heartRate > 0 ? "\(Int(workout.heartRate))" : "--", label: "BPM")
            Button(action: {
                connectivity.sendRunCommand(RunCommand(command: .stop))
                Task { try? await workout.endWorkout() }
            }) {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .onChange(of: connectivity.hapticTrigger) { _, trigger in
            if let trigger { WatchHapticManager.play(trigger.type) }
        }
    }

    func metricRow(value: String, label: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(.body, design: .monospaced).bold())
        }
    }
}
