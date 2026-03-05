# Replan Session Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow users to regenerate their training plan at any time via a "replan" voice session, and show a prompt in PlanView when no plan exists.

**Architecture:** Add a `replan` session type with a dedicated backend prompt that assumes the coach knows the user. Surface entry points in ProfileView (Coach section) and PlanView (empty-state banner). No changes to onboarding or existing session types.

**Tech Stack:** FastAPI + Pipecat (backend), SwiftUI (iOS)

---

### Task 1: Add `replan` session type to backend

**Files:**
- Modify: `pacepilot-server/voice/system_prompts/general.py`

**Step 1: Add the replan prompt and register it**

Open `pacepilot-server/voice/system_prompts/general.py`. Add after the existing `GENERAL_PROMPT`:

```python
REPLAN_PROMPT = """You are PacePilot, an AI running coach. The runner wants to create or update their training plan.

You already know this runner. Start by calling get_plan_status to check if they have an active plan, and update_user_profile (read-only, no changes) to recall their current goals.

Then ask conversationally — one question at a time — only what you need:
1. What's changed? (new race goal, different schedule, updated fitness level)
2. If no recent race time on file, ask for a current 5K estimate or recent race result
3. Which days they prefer to run (if changing)

Once you have enough (goal + pace estimate + preferred days), call generate_training_plan immediately.

Rules:
- Don't re-ask info you already have unless they want to change it.
- One question at a time.
- After generating, confirm: tell them their new plan is ready and what their first workout is.
"""
```

Then add `"replan"` to `SESSION_TYPE_PROMPTS`:

```python
SESSION_TYPE_PROMPTS = {
    "onboarding": ONBOARDING_PROMPT,
    "active_run": ACTIVE_RUN_PROMPT,
    "post_run": POST_RUN_PROMPT,
    "general": GENERAL_PROMPT,
    "pre_run": GENERAL_PROMPT,
    "replan": REPLAN_PROMPT,
}
```

**Step 2: Add greeting trigger for replan**

Open `pacepilot-server/voice/pipeline.py`. In `INITIAL_GREETING_TRIGGERS`, add:

```python
"replan": "The runner wants to update or create their training plan. Check what you already know about them, then ask what they'd like to change.",
```

**Step 3: Verify the server accepts the new session type**

Start the server and hit the session endpoint manually:
```bash
cd pacepilot-server
uvicorn main:app --reload
```
In another terminal:
```bash
python3 -c "
from utils.jwt_utils import create_access_token
print(create_access_token('YOUR_USER_ID'))
"
# Then:
curl -X POST http://localhost:8000/api/voice/session \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"session_type": "replan"}'
```
Expected: JSON with `room_url`, `token`, `session_id` — no 500 error.

**Step 4: Commit**

```bash
cd pacepilot-server
git add voice/system_prompts/general.py voice/pipeline.py
git commit -m "feat: add replan voice session type with dedicated prompt"
```

---

### Task 2: Add `replan` case to iOS SessionType enum

**Files:**
- Modify: `PacePilot/PacePilot/Core/Models/AgentSession.swift`

**Step 1: Add the enum case**

In `AgentSession.SessionType`, add `replan`:

```swift
enum SessionType: String, Codable {
    case onboarding, preRun = "pre_run", activeRun = "active_run",
         postRun = "post_run", general, replan
}
```

**Step 2: Build to verify no compile errors**

In Xcode: Cmd+B or via xcodebuild:
```bash
cd PacePilot
xcodebuild -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' build | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 3: Commit**

```bash
git add PacePilot/PacePilot/Core/Models/AgentSession.swift
git commit -m "feat: add replan session type to iOS AgentSession enum"
```

---

### Task 3: Add "Regenerate Plan" button to ProfileView

**Files:**
- Modify: `PacePilot/PacePilot/Features/Profile/ProfileView.swift`

**Step 1: Add state variable for replan sheet**

In `ProfileView`, add a second `@State` variable below `showCoachSheet`:

```swift
@State private var showReplanSheet = false
```

**Step 2: Add the button to `coachSection`**

The current `coachSection` looks like:
```swift
var coachSection: some View {
    Section {
        Button(action: { showCoachSheet = true }) {
            Label("Talk to Coach", systemImage: "mic.fill")
                .foregroundColor(.accentColor)
        }
        Text("Ask your coach to update your training plan, change your goals, or answer questions.")
            .font(.caption)
            .foregroundColor(.secondary)
    } header: {
        Text("Coach")
    }
}
```

Add a second button after the first:

```swift
var coachSection: some View {
    Section {
        Button(action: { showCoachSheet = true }) {
            Label("Talk to Coach", systemImage: "mic.fill")
                .foregroundColor(.accentColor)
        }
        Button(action: { showReplanSheet = true }) {
            Label("Regenerate Training Plan", systemImage: "arrow.clockwise")
                .foregroundColor(.accentColor)
        }
        Text("Ask your coach to update your training plan, change your goals, or answer questions.")
            .font(.caption)
            .foregroundColor(.secondary)
    } header: {
        Text("Coach")
    }
}
```

**Step 3: Add the replan sheet modifier**

Below the existing `.sheet(isPresented: $showCoachSheet)` modifier, add:

```swift
.sheet(isPresented: $showReplanSheet) {
    ReplanSheet()
}
```

**Step 4: Create `ReplanSheet` view**

Add this struct at the bottom of `ProfileView.swift`, after `ProfileView`:

```swift
// MARK: - Replan Sheet

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
                    .foregroundColor(.accentColor)
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
            Text("Connecting...").foregroundColor(.accentColor)
        case .active:
            Text(vm.agentSpeaking ? "Coach is speaking..." : "Listening...").foregroundColor(.accentColor)
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
            Button(action: { Task { await vm.start() } }) {
                Circle()
                    .fill(Color.accentColor)
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
            ProgressView().tint(.accentColor)
        }
    }
}

@MainActor
final class ReplanViewModel: ObservableObject {
    @Published var sessionState: VoiceSessionState = .idle
    @Published var agentSpeaking = false

    private let voice = VoiceSessionService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        voice.$sessionState.assign(to: &$sessionState)
        voice.$agentSpeaking.assign(to: &$agentSpeaking)
    }

    func start() async { await voice.startSession(type: .replan) }
    func end() async { await voice.endSession() }
}
```

**Step 5: Build to verify**

```bash
xcodebuild -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' build | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 6: Commit**

```bash
git add PacePilot/PacePilot/Features/Profile/ProfileView.swift
git commit -m "feat: add Regenerate Training Plan button to ProfileView"
```

---

### Task 4: Add empty-state banner to PlanView

**Files:**
- Modify: `PacePilot/PacePilot/Features/Plan/PlanView.swift`

**Step 1: Add state for replan sheet**

In `PlanView`, add:

```swift
@State private var showReplanSheet = false
```

**Step 2: Add the empty-state view**

Add this computed property to `PlanView`:

```swift
@ViewBuilder
var emptyPlanBanner: some View {
    if !vm.isLoading && vm.plan == nil {
        VStack(spacing: 12) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No training plan yet")
                .font(.headline)
            Text("Talk to your coach to create a personalised plan.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showReplanSheet = true }) {
                Label("Create Training Plan", systemImage: "mic.fill")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
    }
}
```

**Step 3: Insert banner and sheet into body**

The current `body` is:
```swift
var body: some View {
    NavigationStack {
        VStack {
            DatePicker(...)
            workoutsForSelectedDate
        }
        .navigationTitle("Training Plan")
        .task { await vm.load() }
    }
}
```

Update it to:
```swift
var body: some View {
    NavigationStack {
        VStack {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .accentColor(.accentColor)
                .padding(.horizontal)
            emptyPlanBanner
            workoutsForSelectedDate
        }
        .navigationTitle("Training Plan")
        .task { await vm.load() }
        .sheet(isPresented: $showReplanSheet) {
            ReplanSheet()
        }
    }
}
```

**Step 4: Build to verify**

```bash
xcodebuild -scheme PacePilot -destination 'platform=iOS Simulator,name=iPhone 16' build | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 5: Commit**

```bash
git add PacePilot/PacePilot/Features/Plan/PlanView.swift
git commit -m "feat: show empty-state banner in PlanView when no active plan"
```

---

### Task 5: Manual end-to-end verification

1. Run the backend: `uvicorn main:app --reload` in `pacepilot-server/`
2. Launch app in simulator
3. Navigate to **Profile** → Coach section → tap "Regenerate Training Plan"
   - Sheet should open, tap mic, coach should greet with replan context
   - Say "I want a new 10K plan, I run about 55 minutes" and preferred days
   - Coach should call `generate_training_plan` and confirm
4. Dismiss sheet, navigate to **Plan** tab
   - Calendar should now show with workouts populated for the next weeks
5. Sign out and create a fresh user (no plan), navigate to **Plan** tab
   - Empty-state banner should appear with "Create Training Plan" button
   - Tap it, complete the replan flow, verify plan appears
