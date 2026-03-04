import SwiftUI

struct WatchActiveRunView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 8) {
            if let state = connectivity.runState {
                metricRow(value: RunTimeFormatter.format(seconds: state.elapsedSeconds), label: "TIME")
                metricRow(value: String(format: "%.2f", state.distanceKm), label: "KM")
                metricRow(value: PaceFormatter.format(secondsPerKm: state.paceSecondsPerKm), label: "/KM")
            } else {
                ProgressView()
            }
            Button(action: {
                connectivity.sendRunCommand(RunCommand(command: .stop))
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
