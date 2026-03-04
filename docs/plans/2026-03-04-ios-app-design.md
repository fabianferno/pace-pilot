# PacePilot iOS App — Design Document

**Date:** 2026-03-04
**Status:** Approved
**Scope:** Full iOS app (all phases), Apple Watch companion app
**Build Approach:** Layer-by-layer (Core infrastructure first, then Features)

---

## Architecture Overview

The iOS app is organized into three layers built in sequence:

1. **Core** — Models, networking, services, utilities (no UI dependency)
2. **Features** — SwiftUI views + ViewModels per feature module
3. **Navigation** — AppRouter driving root-level navigation state

---

## Layer 1: Core

### Models (`Core/Models/`)
Codable Swift structs mirroring MongoDB collections:
- `User` — profile, onboarding data, connected services, community tier, preferences
- `TrainingPlan` — pace/HR zones, weeks, workout references
- `Workout` — target distance, pace zones, segments, completion status
- `RunSession` — distance, pace, HR, GPS track, biometric stream, agent interactions
- `Community` — tier, member list, challenges, leaderboard
- `Race` — distance, location, date, registration links, elevation profile
- `AgentSession` — transcript, tool calls, metadata
- `WatchMessage` — typed messages exchanged with Watch (biometricUpdate, runCommand, voiceInput, runStateUpdate, hapticTrigger, workoutSync)

### Networking (`Core/Network/`)
- `APIClient.swift` — URLSession async/await wrapper; JWT injected via `Authorization: Bearer` header; auto-refresh on 401 using stored refresh token
- `WebRTCClient.swift` — Daily.co SDK wrapper; exposes `connect(roomURL:token:)`, `disconnect()`, mic mute/unmute; publishes connection state via Combine

### Auth (`Core/AuthManager.swift`)
- Apple Sign-In via `ASAuthorizationController`
- Exchanges Apple identity token for PacePilot JWT at `POST /api/auth/register` or `POST /api/auth/login`
- Stores access + refresh tokens in Keychain
- Publishes `authState: AuthState` (`.unauthenticated | .authenticated(User)`)

### Services (`Core/Services/`)
- `VoiceSessionService` — requests Daily room from `POST /api/voice/session`; connects WebRTC; streams biometrics every 5s to `POST /api/voice/biometrics`; publishes `sessionState` and `agentSpeaking`
- `HealthKitService` — requests HealthKit permissions; starts `HKWorkoutSession` + `HKLiveWorkoutBuilder`; publishes real-time HR, pace, cadence, calories via Combine
- `LocationService` — CLLocationManager wrapper; publishes GPS coordinates, calculated pace, cumulative distance
- `WorkoutService` — orchestrates HKWorkoutSession lifecycle; collects splits and elevation
- `WatchConnectivityManager` — `WCSession` delegate; sends/receives typed `WatchMessage`; publishes incoming biometric updates from Watch

### Utilities (`Core/Utilities/`)
- `PaceFormatter` — seconds-per-km → "4:32/km" string
- `TimeFormatter` — seconds → "1:23:45" string
- `Constants` — API base URL, Keychain keys, HealthKit quantity types

---

## Layer 2: Features

Each feature is a SwiftUI module with a ViewModel (`@MainActor ObservableObject`) and one or more Views.

### Onboarding (`Features/Onboarding/`)
- `OnboardingView` — minimal UI: logo, animated waveform, "Tap to start" button
- Tap → `VoiceSessionService.startSession(type: .onboarding)`
- Agent conducts intake via voice, calls `update_user_profile` and `generate_training_plan` tools
- On session end → navigate to Home

### Home (`Features/Home/`)
- `HomeView` — today's workout card, weekly stats ring (distance/consistency), quick-start run button
- `HomeViewModel` — fetches `GET /api/workouts/today`, `GET /api/users/me/stats`

### Plan (`Features/Plan/`)
- `PlanView` — monthly calendar grid with workout dots; tap day → `WorkoutDetailView`
- `WorkoutDetailView` — target pace, segments, HR zone, start/skip/reschedule actions
- `PlanViewModel` — fetches `GET /api/plans/active`, `GET /api/plans/{id}/workouts`

### Active Run (`Features/ActiveRun/`)
- `ActiveRunView` — full-screen dark UI: large metrics (pace, distance, time, HR), coaching mode badge, waveform indicator when agent speaking, stop button
- `ActiveRunViewModel` — merges HealthKit + Location publishers; calls `WorkoutService.startWorkout()`; manages `VoiceSessionService` for `active_run` session type; accumulates splits

### Post Run (`Features/PostRun/`)
- `PostRunView` — summary card (distance, time, avg pace, avg HR), MapKit route polyline, verbal debrief waveform, share button
- `PostRunViewModel` — POSTs `RunSession` to `POST /api/runs`; triggers Strava sync if connected; starts post-run voice session

### Community (`Features/Community/`)
- `CommunityView` — user tier badge, weekly leaderboard list, active challenges
- `CommunityViewModel` — fetches `GET /api/communities/me`, leaderboard, challenges, friend activity

### Races (`Features/Races/`)
- `RaceDiscoveryView` — filterable list of upcoming races
- `RaceDetailView` — course info, register-interest button
- `RacesViewModel` — fetches `GET /api/races/discover`

### History (`Features/History/`)
- `RunHistoryView` — paginated list of completed runs
- `RunDetailView` — full breakdown: splits table, MapKit route, HR chart, agent debrief transcript
- `HistoryViewModel` — fetches `GET /api/runs` with pagination

### Profile (`Features/Profile/`)
- `ProfileView` — user info, connected services (Strava OAuth, Google Calendar, Apple Calendar), preferences
- `ProfileViewModel` — fetches profile, manages OAuth flows, calls PATCH `/api/users/me`

---

## Layer 3: Navigation

### `AppRouter` (ObservableObject)
- Root enum: `.unauthenticated`, `.onboarding`, `.main`
- Observes `AuthManager.authState` to switch between unauthenticated (Login/Splash) and main TabView
- Main tab structure: Home | Plan | Community | Races | Profile
- `NavigationStack` + `NavigationPath` per tab for deep-link support

---

## Key Data Flows

### Auth Flow
```
Apple Sign-In → ASAuthorizationController
  → POST /api/auth/login
  → JWT + refresh token → Keychain
  → AuthManager publishes .authenticated(user)
  → AppRouter navigates to .onboarding (first time) or .main
```

### Active Run Flow
```
User taps "Start Run"
  → WorkoutService.startWorkout()        // HKWorkoutSession
  → HealthKitService starts publishers   // HR, pace, cadence
  → LocationService starts publishers   // GPS, distance
  → VoiceSessionService.startSession(type: .active_run)
  → ActiveRunViewModel merges all publishers → updates UI
  → Every 5s: POST /api/voice/biometrics
  → User taps Stop
  → WorkoutService.endWorkout() → collects splits/elevation
  → POST /api/runs
  → Navigate to PostRunView
```

### Voice Flow
```
VoiceSessionService.startSession(type:)
  → POST /api/voice/session → { roomURL, token }
  → WebRTCClient.connect(roomURL, token)
  → Mic audio streamed to Pipecat server
  → Agent audio played back via Daily transport
  → VoiceSessionService publishes agentSpeaking (drives waveform)
```

---

## Watch Integration

`WatchConnectivityManager` sends/receives typed messages:

| Direction | Message | Payload |
|-----------|---------|---------|
| Watch → Phone | `biometricUpdate` | HR, pace, timestamp |
| Watch → Phone | `runCommand` | start / pause / stop |
| Watch → Phone | `voiceInput` | audio data |
| Phone → Watch | `runStateUpdate` | distance, time, pace |
| Phone → Watch | `hapticTrigger` | type (interval, milestone, alert) |
| Phone → Watch | `workoutSync` | today's workout summary |

---

## State Management

- `@StateObject` ViewModels owned by root views; shared via `@EnvironmentObject` where needed
- Combine `Publisher` chains for real-time biometric updates (no polling)
- No third-party state library (YAGNI)

---

## File Structure (Target)

```
PacePilot/
├── App/
│   ├── PacePilotApp.swift
│   └── AppRouter.swift
├── Core/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── TrainingPlan.swift
│   │   ├── Workout.swift
│   │   ├── RunSession.swift
│   │   ├── Community.swift
│   │   ├── Race.swift
│   │   ├── AgentSession.swift
│   │   └── WatchMessage.swift
│   ├── Network/
│   │   ├── APIClient.swift
│   │   └── WebRTCClient.swift
│   ├── AuthManager.swift
│   ├── Services/
│   │   ├── VoiceSessionService.swift
│   │   ├── HealthKitService.swift
│   │   ├── LocationService.swift
│   │   ├── WorkoutService.swift
│   │   └── WatchConnectivityManager.swift
│   └── Utilities/
│       ├── PaceFormatter.swift
│       ├── TimeFormatter.swift
│       └── Constants.swift
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   ├── Plan/
│   ├── ActiveRun/
│   ├── PostRun/
│   ├── Community/
│   ├── Races/
│   ├── History/
│   └── Profile/
└── Resources/
```

---

## Constraints

- iOS 17+ minimum
- SwiftUI-first; UIKit only where SwiftUI has gaps (e.g., camera, certain map interactions)
- Daily.co SDK integrated via Swift Package Manager
- HealthKit, CoreLocation, WatchConnectivity, EventKit frameworks linked
- All API calls async/await; no completion handler callbacks
