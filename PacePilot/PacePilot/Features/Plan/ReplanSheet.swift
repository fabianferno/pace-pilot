import SwiftUI
import Combine

// MARK: - Replan Sheet

@MainActor
final class ReplanViewModel: ObservableObject {
    @Published var sessionState: VoiceSessionState = .idle
    @Published var agentSpeaking = false

    private let voice = VoiceSessionService.shared

    init() {
        voice.$sessionState.assign(to: &$sessionState)
        voice.$agentSpeaking.assign(to: &$agentSpeaking)
    }

    func start() async { await voice.startSession(type: .replan) }
    func end() async { await voice.endSession() }
}

struct ReplanSheet: View {
    @StateObject private var vm = ReplanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer()
                    WaveformView(isActive: vm.agentSpeaking)
                        .frame(height: 60)
                        .padding(.horizontal, 32)
                    statusText
                    actionButton
                    Spacer()
                }
            }
            .navigationTitle("Update Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        Task {
                            await vm.end()
                            dismiss()
                        }
                    }
                    .foregroundColor(.brand)
                }
            }
        }
    }

    @ViewBuilder
    var statusText: some View {
        switch vm.sessionState {
        case .idle:
            Text("Tap to update your plan").foregroundColor(.gray)
        case .connecting:
            Text("Connecting...").foregroundColor(.brand)
        case .active:
            Text(vm.agentSpeaking ? "Coach is speaking..." : "Listening...").foregroundColor(.brand)
        case .disconnecting:
            Text("Ending session...").foregroundColor(.gray)
        case .error(let msg):
            Text("Error: \(msg)").foregroundColor(.red).font(.caption)
        }
    }

    @ViewBuilder
    var actionButton: some View {
        switch vm.sessionState {
        case .idle, .error:
            Button(action: { Task { await vm.start() } }) {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "mic.fill").font(.title2).foregroundColor(.black))
            }
        case .active:
            Button(action: { Task { await vm.end() } }) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "stop.fill").font(.title2).foregroundColor(.white))
            }
        default:
            ProgressView().tint(.brand)
        }
    }
}

#if DEBUG
#Preview("Replan Sheet") {
    ReplanSheet()
        .preferredColorScheme(.dark)
}
#endif
