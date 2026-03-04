import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var runState: RunStateUpdate?
    @Published var hapticTrigger: HapticTrigger?
    @Published var workoutSync: WorkoutSync?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendBiometricUpdate(_ update: BiometricUpdate) {
        guard WCSession.default.isReachable,
              let data = try? encoder.encode(update) else { return }
        WCSession.default.sendMessage([WatchMessageType.biometricUpdate.rawValue: data], replyHandler: nil)
    }

    func sendRunCommand(_ command: RunCommand) {
        guard WCSession.default.isReachable,
              let data = try? encoder.encode(command) else { return }
        WCSession.default.sendMessage([WatchMessageType.runCommand.rawValue: data], replyHandler: nil)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[WatchMessageType.runStateUpdate.rawValue] as? Data,
           let update = try? decoder.decode(RunStateUpdate.self, from: data) {
            Task { @MainActor in self.runState = update }
        }
        if let data = message[WatchMessageType.hapticTrigger.rawValue] as? Data,
           let trigger = try? decoder.decode(HapticTrigger.self, from: data) {
            Task { @MainActor in self.hapticTrigger = trigger }
        }
        if let data = message[WatchMessageType.workoutSync.rawValue] as? Data,
           let sync = try? decoder.decode(WorkoutSync.self, from: data) {
            Task { @MainActor in self.workoutSync = sync }
        }
    }
}
