import Foundation
import UserNotifications
import UIKit
import Combine

enum NotificationCategory: String, CaseIterable {
    case workoutReminder = "workout_reminder"
    case postRun = "post_run"
    case social = "social"
    case raceAlert = "race_alert"

    var displayName: String {
        switch self {
        case .workoutReminder: return "Workout Reminders"
        case .postRun: return "Post-Run Celebrations"
        case .social: return "Social & Community"
        case .raceAlert: return "Race Alerts"
        }
    }

    var description: String {
        switch self {
        case .workoutReminder: return "Reminders for scheduled workouts"
        case .postRun: return "Celebrations for PRs and milestones"
        case .social: return "Friend activity and community updates"
        case .raceAlert: return "Upcoming races and registration deadlines"
        }
    }
}

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var preferences: [NotificationCategory: Bool] = [:]

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults(suiteName: "group.com.crevn.pacepilot")!
    private let api = APIClient.shared

    override init() {
        super.init()
        loadPreferences()
        center.delegate = self
    }

    // MARK: - Permissions

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("Notification auth error: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Device Token

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        Task {
            struct TokenRequest: Encodable {
                let token: String
                let platform: String
            }
            struct OkResponse: Decodable { let ok: Bool }
            _ = try? await api.post("/api/notifications/device-token", body: TokenRequest(token: token, platform: "ios")) as OkResponse
        }
    }

    func handleTokenError(_ error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - Preferences

    func isEnabled(_ category: NotificationCategory) -> Bool {
        preferences[category] ?? true
    }

    func setEnabled(_ category: NotificationCategory, enabled: Bool) {
        preferences[category] = enabled
        defaults.set(enabled, forKey: "notifications_enabled_\(category.rawValue)")
        syncPreferencesToServer()
    }

    private func loadPreferences() {
        for category in NotificationCategory.allCases {
            let key = "notifications_enabled_\(category.rawValue)"
            if defaults.object(forKey: key) != nil {
                preferences[category] = defaults.bool(forKey: key)
            } else {
                preferences[category] = true
            }
        }
    }

    private func syncPreferencesToServer() {
        Task {
            struct PrefsRequest: Encodable {
                let workoutReminder: Bool
                let postRun: Bool
                let social: Bool
                let raceAlert: Bool
            }
            struct PrefsResponse: Decodable {
                let workoutReminder: Bool
                let postRun: Bool
                let social: Bool
                let raceAlert: Bool
            }
            let body = PrefsRequest(
                workoutReminder: isEnabled(.workoutReminder),
                postRun: isEnabled(.postRun),
                social: isEnabled(.social),
                raceAlert: isEnabled(.raceAlert)
            )
            _ = try? await api.put("/api/notifications/preferences", body: body) as PrefsResponse
        }
    }

    // MARK: - Local Notifications: Workout Reminders

    func scheduleWorkoutReminders(for workouts: [Workout]) {
        guard isEnabled(.workoutReminder) else { return }

        center.removePendingNotificationRequests(withIdentifiers:
            workouts.flatMap { w in
                ["workout_morning_\(w.id)", "workout_before_\(w.id)"]
            }
        )

        let calendar = Calendar.current
        let now = Date()

        for workout in workouts {
            guard !workout.isCompleted, !workout.isSkipped, workout.scheduledDate > now else { continue }

            var morningComponents = calendar.dateComponents([.year, .month, .day], from: workout.scheduledDate)
            morningComponents.hour = 7
            morningComponents.minute = 0

            let morningContent = UNMutableNotificationContent()
            morningContent.title = "Today's Workout"
            morningContent.body = "\(workout.type.rawValue.capitalized) run — \(String(format: "%.1f", workout.targetDistanceKm)) km"
            morningContent.sound = .default
            morningContent.categoryIdentifier = NotificationCategory.workoutReminder.rawValue

            let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: false)
            let morningRequest = UNNotificationRequest(
                identifier: "workout_morning_\(workout.id)",
                content: morningContent,
                trigger: morningTrigger
            )
            center.add(morningRequest)

            if let oneHourBefore = calendar.date(byAdding: .hour, value: -1, to: workout.scheduledDate),
               oneHourBefore > now {
                let beforeComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneHourBefore)

                let beforeContent = UNMutableNotificationContent()
                beforeContent.title = "Lace Up!"
                beforeContent.body = "Your \(workout.type.rawValue) run starts in 1 hour"
                beforeContent.sound = .default
                beforeContent.categoryIdentifier = NotificationCategory.workoutReminder.rawValue

                let beforeTrigger = UNCalendarNotificationTrigger(dateMatching: beforeComponents, repeats: false)
                let beforeRequest = UNNotificationRequest(
                    identifier: "workout_before_\(workout.id)",
                    content: beforeContent,
                    trigger: beforeTrigger
                )
                center.add(beforeRequest)
            }
        }
    }

    // MARK: - Local Notifications: Post-Run Celebrations

    func sendPostRunCelebration(session: RunSession, previousBestPace: Double? = nil) {
        guard isEnabled(.postRun) else { return }

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = NotificationCategory.postRun.rawValue
        content.sound = .default
        content.userInfo = ["route": "run/\(session.id)"]

        if let previousBest = previousBestPace, session.avgPaceSecondsPerKm < previousBest {
            let paceMinutes = Int(session.avgPaceSecondsPerKm) / 60
            let paceSeconds = Int(session.avgPaceSecondsPerKm) % 60
            content.title = "New PR!"
            content.body = "You ran \(String(format: "%.1f", session.distanceKm)) km at \(paceMinutes):\(String(format: "%02d", paceSeconds))/km"
        } else {
            content.title = "Run Complete!"
            let durationMin = session.durationSeconds / 60
            content.body = "\(String(format: "%.1f", session.distanceKm)) km in \(durationMin) minutes. Great work!"
        }

        let request = UNNotificationRequest(
            identifier: "post_run_\(session.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        center.add(request)
    }

    // MARK: - Deep Link Handling

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        if let route = userInfo["route"] as? String {
            AppRouter.shared.handleNotificationRoute(route)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            handleNotificationResponse(response)
        }
    }
}
