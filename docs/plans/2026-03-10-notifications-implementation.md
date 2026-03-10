# Notifications Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add local and remote push notifications to PacePilot — workout reminders, post-run celebrations, social/community alerts, and race alerts — across iOS and Python backend.

**Architecture:** Unified `NotificationService` singleton on iOS handles permissions, local scheduling, APNs token registration, remote payload parsing, deep linking, and per-category preferences. Backend gets new endpoints for device token registration and notification preferences, plus an APNs sending service using `aioapns`.

**Tech Stack:** iOS: UserNotifications framework, SwiftUI. Backend: FastAPI, Motor, aioapns.

---

### Task 1: Backend — Add device token and notification preferences fields to UserDB

**Files:**
- Modify: `pacepilot-server/db/models.py`

**Step 1: Add fields to UserDB model**

In `pacepilot-server/db/models.py`, add these fields to the `UserDB` class after `city`:

```python
device_tokens: List[dict] = []  # [{"token": "...", "platform": "ios", "updated_at": datetime}]
notification_preferences: dict = Field(default_factory=lambda: {
    "workout_reminder": True,
    "post_run": True,
    "social": True,
    "race_alert": True,
})
```

**Step 2: Commit**

```bash
git add pacepilot-server/db/models.py
git commit -m "feat(backend): add device token and notification prefs to UserDB"
```

---

### Task 2: Backend — Add device token and preferences methods to UserRepository

**Files:**
- Modify: `pacepilot-server/db/repositories/user_repo.py`

**Step 1: Add repository methods**

Add these methods to `UserRepository` in `pacepilot-server/db/repositories/user_repo.py`:

```python
async def upsert_device_token(self, user_id: str, token: str, platform: str) -> None:
    """Add or update a device token for a user. Replaces existing token for same platform."""
    await self.col.update_one(
        {"_id": ObjectId(user_id)},
        {
            "$pull": {"device_tokens": {"platform": platform}},
        }
    )
    await self.col.update_one(
        {"_id": ObjectId(user_id)},
        {
            "$push": {
                "device_tokens": {
                    "token": token,
                    "platform": platform,
                    "updated_at": datetime.utcnow(),
                }
            },
            "$set": {"updated_at": datetime.utcnow()},
        }
    )

async def remove_device_token(self, user_id: str, token: str) -> None:
    await self.col.update_one(
        {"_id": ObjectId(user_id)},
        {
            "$pull": {"device_tokens": {"token": token}},
            "$set": {"updated_at": datetime.utcnow()},
        }
    )

async def update_notification_preferences(self, user_id: str, prefs: dict) -> None:
    await self.col.update_one(
        {"_id": ObjectId(user_id)},
        {
            "$set": {
                "notification_preferences": prefs,
                "updated_at": datetime.utcnow(),
            }
        }
    )

async def get_users_with_tokens(self, user_ids: list[str]) -> list[UserDB]:
    """Fetch users who have device tokens registered."""
    cursor = self.col.find({
        "_id": {"$in": [ObjectId(uid) for uid in user_ids]},
        "device_tokens.0": {"$exists": True},
    })
    return [UserDB(**doc) async for doc in cursor]
```

**Step 2: Commit**

```bash
git add pacepilot-server/db/repositories/user_repo.py
git commit -m "feat(backend): add device token and notification prefs repo methods"
```

---

### Task 3: Backend — Create notifications route

**Files:**
- Create: `pacepilot-server/api/routes/notifications.py`

**Step 1: Create the route file**

Create `pacepilot-server/api/routes/notifications.py`:

```python
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository

router = APIRouter()


class DeviceTokenRequest(BaseModel):
    token: str
    platform: str = "ios"


class NotificationPreferencesRequest(BaseModel):
    workout_reminder: Optional[bool] = None
    post_run: Optional[bool] = None
    social: Optional[bool] = None
    race_alert: Optional[bool] = None


@router.post("/device-token")
async def register_device_token(
    body: DeviceTokenRequest,
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    await repo.upsert_device_token(user_id, body.token, body.platform)
    return {"ok": True}


@router.delete("/device-token")
async def remove_device_token(
    body: DeviceTokenRequest,
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    await repo.remove_device_token(user_id, body.token)
    return {"ok": True}


@router.get("/preferences")
async def get_notification_preferences(
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    if not user:
        return {"workout_reminder": True, "post_run": True, "social": True, "race_alert": True}
    return user.notification_preferences


@router.put("/preferences")
async def update_notification_preferences(
    body: NotificationPreferencesRequest,
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    current = user.notification_preferences if user else {}
    updates = body.model_dump(exclude_none=True)
    merged = {**{"workout_reminder": True, "post_run": True, "social": True, "race_alert": True}, **current, **updates}
    await repo.update_notification_preferences(user_id, merged)
    return merged
```

**Step 2: Register the router in main.py**

In `pacepilot-server/main.py`, add the import and include the router:

```python
# Add to imports:
from api.routes import auth, users, plans, workouts, runs, communities, community_runs, calendar, strava, voice, notifications

# Add after the voice router line:
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
```

**Step 3: Commit**

```bash
git add pacepilot-server/api/routes/notifications.py pacepilot-server/main.py
git commit -m "feat(backend): add notification device-token and preferences endpoints"
```

---

### Task 4: Backend — Create APNs notification sending service

**Files:**
- Create: `pacepilot-server/services/notification_service.py`
- Modify: `pacepilot-server/requirements.txt`

**Step 1: Add aioapns to requirements.txt**

Add to `pacepilot-server/requirements.txt`:

```
aioapns>=3.2
```

**Step 2: Create notification_service.py**

Create `pacepilot-server/services/notification_service.py`:

```python
import os
import json
import logging
from typing import Optional
from aioapns import APNs, NotificationRequest, PushType

logger = logging.getLogger(__name__)


class NotificationService:
    _instance: Optional["NotificationService"] = None

    def __init__(self):
        self._client: Optional[APNs] = None

    @classmethod
    def get_instance(cls) -> "NotificationService":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    async def _get_client(self) -> APNs:
        if self._client is None:
            key_path = os.getenv("APNS_KEY_PATH")
            key_id = os.getenv("APNS_KEY_ID")
            team_id = os.getenv("APNS_TEAM_ID")
            topic = os.getenv("APNS_TOPIC", "com.crevn.pacepilot")
            use_sandbox = os.getenv("APP_ENV", "development") == "development"

            if not all([key_path, key_id, team_id]):
                logger.warning("APNs not configured — missing APNS_KEY_PATH, APNS_KEY_ID, or APNS_TEAM_ID")
                raise RuntimeError("APNs not configured")

            self._client = APNs(
                key=key_path,
                key_id=key_id,
                team_id=team_id,
                topic=topic,
                use_sandbox=use_sandbox,
            )
        return self._client

    async def send_push(
        self,
        device_token: str,
        title: str,
        body: str,
        category: str,
        route: Optional[str] = None,
        metadata: Optional[dict] = None,
        badge: Optional[int] = None,
    ) -> bool:
        """Send a push notification to a single device token."""
        try:
            client = await self._get_client()
        except RuntimeError:
            logger.warning("Skipping push — APNs not configured")
            return False

        payload = {
            "aps": {
                "alert": {"title": title, "body": body},
                "sound": "default",
                "category": category,
            }
        }
        if badge is not None:
            payload["aps"]["badge"] = badge
        if route:
            payload["route"] = route
        if metadata:
            payload["metadata"] = metadata

        request = NotificationRequest(
            device_token=device_token,
            message=payload,
            push_type=PushType.ALERT,
        )
        response = await client.send_notification(request)
        if not response.is_successful:
            logger.error(f"APNs error for {device_token[:8]}...: {response.description}")
            return False
        return True

    async def send_to_user(
        self,
        user_tokens: list[dict],
        title: str,
        body: str,
        category: str,
        route: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> int:
        """Send push to all of a user's device tokens. Returns count of successful sends."""
        sent = 0
        for token_entry in user_tokens:
            if token_entry.get("platform") == "ios":
                success = await self.send_push(
                    device_token=token_entry["token"],
                    title=title,
                    body=body,
                    category=category,
                    route=route,
                    metadata=metadata,
                )
                if success:
                    sent += 1
        return sent
```

**Step 3: Commit**

```bash
git add pacepilot-server/services/notification_service.py pacepilot-server/requirements.txt
git commit -m "feat(backend): add APNs notification sending service via aioapns"
```

---

### Task 5: iOS — Add `put` method to APIClient

**Files:**
- Modify: `PacePilot/PacePilot/Core/Network/APIClient.swift`

**Step 1: Add put method**

In `APIClient.swift`, add after the `patch` method (line ~68):

```swift
func put<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
    try await request(method: "PUT", path: path, body: body)
}
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/Core/Network/APIClient.swift
git commit -m "feat(ios): add put method to APIClient"
```

---

### Task 6: iOS — Add `remote-notification` to Info.plist background modes

**Files:**
- Modify: `PacePilot/PacePilot/Info.plist`

**Step 1: Add remote-notification background mode**

In `PacePilot/PacePilot/Info.plist`, add `remote-notification` to the `UIBackgroundModes` array:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>location</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/Info.plist
git commit -m "feat(ios): add remote-notification background mode to Info.plist"
```

---

### Task 7: iOS — Create NotificationService

**Files:**
- Create: `PacePilot/PacePilot/Core/Services/NotificationService.swift`

**Step 1: Create the NotificationService**

Create `PacePilot/PacePilot/Core/Services/NotificationService.swift`:

```swift
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

        // Cancel existing workout reminders
        center.removePendingNotificationRequests(withIdentifiers:
            workouts.flatMap { w in
                ["workout_morning_\(w.id)", "workout_before_\(w.id)"]
            }
        )

        let calendar = Calendar.current
        let now = Date()

        for workout in workouts {
            guard !workout.isCompleted, !workout.isSkipped, workout.scheduledDate > now else { continue }

            // Morning-of notification at 7 AM
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

            // 1 hour before notification
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

        // Check for PR
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
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/Core/Services/NotificationService.swift
git commit -m "feat(ios): add NotificationService with local scheduling and APNs support"
```

---

### Task 8: iOS — Add deep link routing to AppRouter

**Files:**
- Modify: `PacePilot/PacePilot/App/AppRouter.swift`

**Step 1: Add selectedTab and handleNotificationRoute**

In `PacePilot/PacePilot/App/AppRouter.swift`, add a `selectedTab` property and the routing method:

```swift
// Add after the @Published var route line:
@Published var selectedTab: Int = 0
@Published var pendingRunId: String?
@Published var pendingRaceId: String?

// Add after init:
func handleNotificationRoute(_ route: String) {
    guard self.route == .main else { return }

    let parts = route.split(separator: "/").map(String.init)

    switch parts.first {
    case "run":
        if parts.count > 1 {
            pendingRunId = parts[1]
        }
        selectedTab = 3 // Runs tab
    case "community":
        selectedTab = 2
    case "races":
        if parts.count > 1 {
            pendingRaceId = parts[1]
        }
        selectedTab = 3
    case "plan":
        selectedTab = 1
    default:
        break
    }
}
```

**Step 2: Update MainTabView to use selectedTab binding**

In `PacePilot/PacePilot/PacePilotApp.swift`, update `MainTabView` to bind to `AppRouter.selectedTab`:

```swift
struct MainTabView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
                .tag(1)
            CommunityView()
                .tabItem { Label("Community", systemImage: "person.3.fill") }
                .tag(2)
            RunDiscoveryView()
                .tabItem { Label("Runs", systemImage: "figure.run") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .accentColor(.accentColor)
    }
}
```

**Step 3: Commit**

```bash
git add PacePilot/PacePilot/App/AppRouter.swift PacePilot/PacePilot/PacePilotApp.swift
git commit -m "feat(ios): add notification deep link routing to AppRouter"
```

---

### Task 9: iOS — Wire AppDelegate for APNs and init NotificationService

**Files:**
- Modify: `PacePilot/PacePilot/PacePilotApp.swift`

**Step 1: Add AppDelegate class and wire into PacePilotApp**

In `PacePilot/PacePilot/PacePilotApp.swift`, add the AppDelegate class before `@main` and the adaptor inside `PacePilotApp`:

```swift
// Add before @main:
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationService.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithDeviceToken error: Error
    ) {
        NotificationService.shared.handleTokenError(error)
    }
}

// Inside PacePilotApp, add:
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

// In the body, add .task after the existing .task:
.task {
    await NotificationService.shared.requestAuthorization()
}
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/PacePilotApp.swift
git commit -m "feat(ios): wire AppDelegate for APNs token handling"
```

---

### Task 10: iOS — Integrate workout reminders into PlanViewModel

**Files:**
- Modify: `PacePilot/PacePilot/Features/Plan/PlanViewModel.swift`

**Step 1: Schedule notifications after loading workouts**

In `PacePilot/PacePilot/Features/Plan/PlanViewModel.swift`, add a call to schedule reminders at the end of the `load()` method, after workouts are fetched:

```swift
// Add after the line: completedRuns = (try? await api.get("/api/runs")) ?? []
NotificationService.shared.scheduleWorkoutReminders(for: workouts)
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/Features/Plan/PlanViewModel.swift
git commit -m "feat(ios): schedule workout reminder notifications on plan load"
```

---

### Task 11: iOS — Integrate post-run celebrations into PostRunViewModel

**Files:**
- Modify: `PacePilot/PacePilot/Features/PostRun/PostRunViewModel.swift`

**Step 1: Fire celebration notification after saving run**

In `PacePilot/PacePilot/Features/PostRun/PostRunViewModel.swift`, add the celebration call inside `saveAndDebrief`, after `savedSession` is set:

```swift
// Add after: savedSession = try await api.post("/api/runs", body: run)
if let session = savedSession {
    NotificationService.shared.sendPostRunCelebration(session: session)
}
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/Features/PostRun/PostRunViewModel.swift
git commit -m "feat(ios): send post-run celebration notification after saving run"
```

---

### Task 12: iOS — Create NotificationPreferencesView

**Files:**
- Create: `PacePilot/PacePilot/Features/Profile/NotificationPreferencesView.swift`

**Step 1: Create the preferences view**

Create `PacePilot/PacePilot/Features/Profile/NotificationPreferencesView.swift`:

```swift
import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var notifications = NotificationService.shared

    var body: some View {
        Form {
            if !notifications.isAuthorized {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notifications are disabled")
                            .font(.headline)
                        Text("Enable notifications in Settings to receive workout reminders and updates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }

            Section("Notification Types") {
                ForEach(NotificationCategory.allCases, id: \.rawValue) { category in
                    Toggle(isOn: Binding(
                        get: { notifications.isEnabled(category) },
                        set: { notifications.setEnabled(category, enabled: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.displayName)
                            Text(category.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!notifications.isAuthorized)
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            await notifications.checkAuthorizationStatus()
        }
    }
}

#if DEBUG
#Preview("Notification Preferences") {
    NavigationStack {
        NotificationPreferencesView()
    }
    .preferredColorScheme(.dark)
}
#endif
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/Features/Profile/NotificationPreferencesView.swift
git commit -m "feat(ios): add notification preferences view with per-category toggles"
```

---

### Task 13: iOS — Add notification preferences link to ProfileView

**Files:**
- Modify: `PacePilot/PacePilot/Features/Profile/ProfileView.swift`

**Step 1: Add NavigationLink to notification preferences**

In `PacePilot/PacePilot/Features/Profile/ProfileView.swift`, add a new section before the `coachSection` in the Form body. Add a computed property:

```swift
// Add this computed property alongside the other section properties:
var notificationsSection: some View {
    Section {
        NavigationLink {
            NotificationPreferencesView()
        } label: {
            Label("Notifications", systemImage: "bell.fill")
        }
    }
}
```

Then add `notificationsSection` to the Form body before `coachSection`:

```swift
Form {
    personalSection
    trainingGoalSection
    scheduleSection
    heartRateSection
    notificationsSection    // <-- add this line
    coachSection
    connectionsSection
    accountSection
}
```

**Step 2: Commit**

```bash
git add PacePilot/PacePilot/Features/Profile/ProfileView.swift
git commit -m "feat(ios): add notifications link to profile settings"
```

---

### Task 14: Backend — Hook notification sends into community run and race events

**Files:**
- Modify: `pacepilot-server/api/routes/community_runs.py` (if run completion endpoint exists)
- Modify: `pacepilot-server/api/routes/runs.py` (to notify friends on run completion)

**Step 1: Check existing run completion and community endpoints**

Read `pacepilot-server/api/routes/runs.py` and `pacepilot-server/api/routes/community_runs.py` to find where runs are saved and community events are created.

**Step 2: Add notification triggers**

After a run is saved in the runs route, send a social notification to the user's community members. After a race is created, notify users in the same city. Use the `NotificationService.get_instance()` to send pushes.

Example integration pattern (adapt to actual code):

```python
from services.notification_service import NotificationService

# After run is saved:
notifier = NotificationService.get_instance()
# Get community members' tokens from repo
# Send push to each with category="social", route=f"run/{run_id}"
```

**Step 3: Commit**

```bash
git add pacepilot-server/api/routes/runs.py pacepilot-server/api/routes/community_runs.py
git commit -m "feat(backend): trigger social push notifications on run completion"
```

---

### Task 15: Verify and final commit

**Step 1: Verify iOS builds**

Open Xcode and build the project, or run:
```bash
cd PacePilot && xcodebuild -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

**Step 2: Verify backend starts**

```bash
cd pacepilot-server && pip install -r requirements.txt && python -c "from api.routes import notifications; print('OK')"
```

**Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address build issues from notifications feature"
```
