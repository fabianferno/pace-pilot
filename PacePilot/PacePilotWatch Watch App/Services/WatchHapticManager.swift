import WatchKit

enum WatchHapticManager {
    static func play(_ type: HapticTrigger.HapticType) {
        let hapticType: WKHapticType
        switch type {
        case .intervalStart: hapticType = .start
        case .intervalEnd:   hapticType = .stop
        case .milestone:     hapticType = .success
        case .paceAlert, .heartRateAlert: hapticType = .directionUp
        }
        WKInterfaceDevice.current().play(hapticType)
    }
}
