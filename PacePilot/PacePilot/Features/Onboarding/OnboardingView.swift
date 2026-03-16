import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var sessionState: VoiceSessionState = .idle
    @Published var agentSpeaking = false

    private let voice = VoiceSessionService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        voice.$sessionState.assign(to: &$sessionState)
        voice.$agentSpeaking.assign(to: &$agentSpeaking)
    }

    func startOnboarding() async {
        await voice.startSession(type: .onboarding)
    }

    func endOnboarding() async {
        await voice.endSession()
        await AuthManager.shared.validateSession()
    }
}

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 48) {
                Spacer()
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                Text("Meet Your Coach")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("Tap below and say hello — your AI running coach is ready to learn about you.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                WaveformView(isActive: vm.agentSpeaking)
                    .frame(height: 60)
                    .padding(.horizontal, 32)
                statusText
                actionButton
                Spacer()
            }
        }
    }

    @ViewBuilder
    var statusText: some View {
        switch vm.sessionState {
        case .idle:
            Text("Tap to start").foregroundColor(.gray)
        case .connecting:
            Text("Connecting...").foregroundColor(.brand)
        case .active:
            Text(vm.agentSpeaking ? "Coach is speaking..." : "Listening...").foregroundColor(.brand)
        case .disconnecting:
            Text("Finishing up...").foregroundColor(.gray)
        case .error(let msg):
            Text("Error: \(msg)").foregroundColor(.red).font(.caption)
        }
    }

    @ViewBuilder
    var actionButton: some View {
        switch vm.sessionState {
        case .idle, .error:
            Button(action: { Task { await vm.startOnboarding() } }) {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "mic.fill").font(.title).foregroundColor(.black))
            }
        case .active:
            Button(action: { Task { await vm.endOnboarding() } }) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "stop.fill").font(.title).foregroundColor(.white))
            }
        default:
            ProgressView().tint(.brand)
        }
    }
}

#if DEBUG
#Preview("Onboarding") {
    OnboardingView()
        .preferredColorScheme(.dark)
}
#endif
