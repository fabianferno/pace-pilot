# Notifications Feature Design

## Overview

Add push and local notifications to PacePilot across iOS and backend. Four notification categories: workout reminders, post-run celebrations, social/community, and race alerts.

## Architecture

### Approach: Unified NotificationService

Single `NotificationService` singleton in `Core/Services/` following existing service pattern (`@MainActor`, `@Published` state). Handles both local and remote notifications.

## Notification Categories

| Category | Type | Trigger |
|----------|------|---------|
| `workout_reminder` | Local | Morning-of at 7 AM + 1hr before scheduled time |
| `post_run` | Local | Fired after run ends from PostRunViewModel |
| `social` | Remote (APNs) | Backend pushes on friend activity, tier change |
| `race_alert` | Remote (APNs) | Backend pushes on new races, registration deadlines |

## iOS Components

### New Files

- `Core/Services/NotificationService.swift` — Main service: permissions, scheduling, APNs, preferences
- `Features/Profile/NotificationPreferencesView.swift` — Per-category toggle UI

### Modified Files

- `PacePilotApp.swift` — Add `@UIApplicationDelegateAdaptor`, init NotificationService, wire delegate
- `App/AppRouter.swift` — Add `handleNotificationRoute(_:)` for deep linking
- `Features/Plan/PlanViewModel.swift` — Call `scheduleWorkoutReminders` when plan loads
- `Features/PostRun/PostRunViewModel.swift` — Call `sendPostRunCelebration` after run completes
- `Features/Profile/ProfileView.swift` — Add navigation link to notification preferences
- `Core/Network/APIClient.swift` — Add `registerDeviceToken` and `updateNotificationPreferences` methods
- `Info.plist` — Add `remote-notification` to `UIBackgroundModes`

### AppDelegate Bridge

SwiftUI app needs `@UIApplicationDelegateAdaptor` for APNs token callbacks. `UNUserNotificationCenterDelegate` conformed by `NotificationService`.

### Deep Link Routing

Notification payloads include a `route` field parsed by `AppRouter.handleNotificationRoute(_:)`.

| Route | Action |
|-------|--------|
| `run/{runId}` | Navigate to run detail |
| `community` | Navigate to community tab |
| `races/{raceId}` | Navigate to race detail |
| `plan` | Navigate to plan tab |

### Preferences

Per-category toggles stored in `UserDefaults(suiteName: "group.com.crevn.pacepilot")` with key pattern `notifications_enabled_{category}`. Synced to backend.

## Backend Components

### New Endpoints

```
POST /api/users/me/device-token
Body: { "token": "...", "platform": "ios" }

PUT /api/users/me/notification-preferences
Body: { "workout_reminder": true, "post_run": true, "social": true, "race_alert": false }
```

### APNs Payload Format

```json
{
  "aps": {
    "alert": { "title": "...", "body": "..." },
    "sound": "default",
    "badge": 1,
    "category": "social"
  },
  "route": "community",
  "metadata": { "userId": "...", "runId": "..." }
}
```

### New Backend Files

- `routes/notifications.py` — Device token registration + preferences endpoints
- `services/notification_service.py` — APNs sending via `aioapns`

### Modified Backend Files

- `main.py` — Register notifications router
- `db/repositories/user_repository.py` — Device token & prefs storage
- `requirements.txt` — Add `aioapns`

## Data Flow

### Local Notifications

PlanViewModel loads workouts → NotificationService.scheduleWorkoutReminders → UNCalendarNotificationTrigger (7 AM morning-of + 1hr before)

PostRunViewModel.finishRun → NotificationService.sendPostRunCelebration → checks PRs/milestones → fires local notification

### Remote Notifications

App launch → registerForRemoteNotifications → token → POST /api/users/me/device-token

Backend event → APNs → iOS → UNUserNotificationCenterDelegate → AppRouter.handleNotificationRoute
