import SwiftUI

struct ActiveRunView: View {
    @StateObject private var vm = ActiveRunViewModel()
    @State private var runResult: NewRunRequest?
    @State private var showPostRun = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if vm.isRunning {
                runningMetrics
            } else {
                startPrompt
            }
        }
        .statusBarHidden()
        .task { await vm.startRun() }
        .fullScreenCover(isPresented: $showPostRun) {
            if let result = runResult {
                PostRunView(runRequest: result)
            }
        }
    }

    var startPrompt: some View {
        VStack(spacing: 24) {
            ProgressView().tint(.orange).scaleEffect(1.5)
            Text("Getting ready...").foregroundColor(.white)
        }
    }

    var runningMetrics: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { Task {
                    runResult = await vm.stopRun()
                    showPostRun = true
                }}) {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
                if vm.agentSpeaking {
                    Label("Coach", systemImage: "waveform")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
            Spacer()

            // Main metrics
            VStack(spacing: 24) {
                metricBlock(value: vm.pace, label: "PACE /km")
                HStack(spacing: 40) {
                    metricBlock(value: String(format: "%.2f", vm.distanceKm), label: "KM")
                    metricBlock(value: RunTimeFormatter.format(seconds: vm.elapsedSeconds), label: "TIME")
                }
                metricBlock(value: vm.heartRate > 0 ? "\(Int(vm.heartRate))" : "--", label: "BPM")
            }

            Spacer()
            if vm.agentSpeaking {
                WaveformView(isActive: true)
                    .frame(height: 40)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }

    func metricBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
