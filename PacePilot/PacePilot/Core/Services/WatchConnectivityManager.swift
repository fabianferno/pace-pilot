import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published private(set) var lastBiometricUpdate: BiometricUpdate?
    @Published private(set) var lastRunCommand: RunCommand?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func send(_ update: RunStateUpdate) {
        guard WCSession.default.isReachable else { return }
        if let data = try? encoder.encode(update) {
            WCSession.default.sendMessage(
                [WatchMessageType.runStateUpdate.rawValue: data],
                replyHandler: nil
            )
        }
    }

    func send(_ trigger: HapticTrigger) {
        guard WCSession.default.isReachable else { return }
        if let data = try? encoder.encode(trigger) {
            WCSession.default.sendMessage(
                [WatchMessageType.hapticTrigger.rawValue: data],
                replyHandler: nil
            )
        }
    }

    func send(_ sync: WorkoutSync) {
        guard WCSession.default.isReachable else { return }
        if let data = try? encoder.encode(sync) {
            WCSession.default.sendMessage(
                [WatchMessageType.workoutSync.rawValue: data],
                replyHandler: nil
            )
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[WatchMessageType.biometricUpdate.rawValue] as? Data,
           let update = try? decoder.decode(BiometricUpdate.self, from: data) {
            Task { @MainActor in self.lastBiometricUpdate = update }
        }
        if let data = message[WatchMessageType.runCommand.rawValue] as? Data,
           let cmd = try? decoder.decode(RunCommand.self, from: data) {
            Task { @MainActor in self.lastRunCommand = cmd }
        }
    }
}
