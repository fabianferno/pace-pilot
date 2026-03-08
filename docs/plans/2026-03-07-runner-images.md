# Runner Images Integration — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate three runner images across HomeView (animated GIF hero), CommunityView (female runner banner), and RunDiscoveryView (male runner banner).

**Architecture:** PNG images go into `Assets.xcassets` as imagesets (auto-discovered by Xcode). The GIF is copied into the app directory as a bundle resource (auto-bundled by folder-based project). A `GIFImageView` UIViewRepresentable drives animation. Each screen gets a ZStack card banner.

**Tech Stack:** SwiftUI, UIKit (UIViewRepresentable + UIImageView for GIF), Xcode folder-based project (no pbxproj edits needed — all files auto-discovered)

---

### Task 1: Add RunnerFemale imageset to Assets.xcassets

**Files:**
- Create: `PacePilot/PacePilot/Assets.xcassets/RunnerFemale.imageset/Contents.json`
- Copy: `app-images/female-runner-transparent-bg-medium-stride.png` → `PacePilot/PacePilot/Assets.xcassets/RunnerFemale.imageset/RunnerFemale.png`

**Step 1: Create the imageset folder and Contents.json**

```json
{
  "images" : [
    {
      "filename" : "RunnerFemale.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 2: Copy the PNG**

```bash
cp app-images/female-runner-transparent-bg-medium-stride.png \
   PacePilot/PacePilot/Assets.xcassets/RunnerFemale.imageset/RunnerFemale.png
```

**Step 3: Verify**

Open `Assets.xcassets` in Xcode — `RunnerFemale` should appear as a named image asset.

**Step 4: Commit**

```bash
git add PacePilot/PacePilot/Assets.xcassets/RunnerFemale.imageset/
git commit -m "chore: add RunnerFemale image asset"
```

---

### Task 2: Add RunnerMale imageset to Assets.xcassets

**Files:**
- Create: `PacePilot/PacePilot/Assets.xcassets/RunnerMale.imageset/Contents.json`
- Copy: `app-images/male-runner-transparent-bg-long-stride.png` → `PacePilot/PacePilot/Assets.xcassets/RunnerMale.imageset/RunnerMale.png`

**Step 1: Create the imageset folder and Contents.json**

```json
{
  "images" : [
    {
      "filename" : "RunnerMale.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 2: Copy the PNG**

```bash
cp app-images/male-runner-transparent-bg-long-stride.png \
   PacePilot/PacePilot/Assets.xcassets/RunnerMale.imageset/RunnerMale.png
```

**Step 3: Commit**

```bash
git add PacePilot/PacePilot/Assets.xcassets/RunnerMale.imageset/
git commit -m "chore: add RunnerMale image asset"
```

---

### Task 3: Copy GIF to app bundle

The project uses a folder-based Xcode format — any file placed inside the `PacePilot/PacePilot/` directory is automatically bundled.

**Files:**
- Copy: `app-images/artistic-runner.gif` → `PacePilot/PacePilot/Resources/artistic-runner.gif`

**Step 1: Create the Resources directory and copy GIF**

```bash
mkdir -p PacePilot/PacePilot/Resources
cp app-images/artistic-runner.gif PacePilot/PacePilot/Resources/artistic-runner.gif
```

**Step 2: Verify in Xcode**

Open Xcode, expand the PacePilot group in the navigator. The `Resources/` folder and `artistic-runner.gif` should appear. Build the app (Cmd+B) and confirm no errors. To confirm it's bundled:

```swift
// Quick test in a playground or breakpoint:
let url = Bundle.main.url(forResource: "artistic-runner", withExtension: "gif")
// url should not be nil
```

**Step 3: Commit**

```bash
git add PacePilot/PacePilot/Resources/artistic-runner.gif
git commit -m "chore: add artistic-runner GIF to bundle resources"
```

---

### Task 4: Create GIFImageView utility

**Files:**
- Create: `PacePilot/PacePilot/Core/Views/GIFImageView.swift`

**Step 1: Write the file**

```swift
import SwiftUI
import UIKit

struct GIFImageView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        if let url = Bundle.main.url(forResource: name, withExtension: "gif"),
           let data = try? Data(contentsOf: url),
           let animated = UIImage.animatedImage(withAnimatedGIFData: data) {
            imageView.image = animated
            imageView.startAnimating()
        }

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}
```

**Step 2: Build to verify it compiles (Cmd+B in Xcode)**

Expected: Build succeeds, no errors.

**Step 3: Commit**

```bash
git add PacePilot/PacePilot/Core/Views/GIFImageView.swift
git commit -m "feat: add GIFImageView UIViewRepresentable utility"
```

---

### Task 5: Rewrite HomeView greetingCard as animated GIF hero

**Files:**
- Modify: `PacePilot/PacePilot/Features/Home/HomeView.swift`

**What to change:** Replace the `greetingCard` computed var (lines 45–64) with a `ZStack` hero card. The GIF fills the background, a gradient overlay ensures text legibility, greeting text sits bottom-left in white.

**Step 1: Replace `greetingCard`**

```swift
var greetingCard: some View {
    ZStack(alignment: .bottomLeading) {
        // Background: animated GIF
        GIFImageView(name: "artistic-runner")
            .frame(maxWidth: .infinity)
            .frame(height: 180)

        // Gradient overlay for text legibility
        LinearGradient(
            colors: [.black.opacity(0.6), .black.opacity(0.1), .clear],
            startPoint: .bottom,
            endPoint: .top
        )

        // Greeting text
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.greetingLine)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(vm.motivationLine)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding()
    }
    .frame(height: 180)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}
```

Also remove the `Image("AppLogo")` from `greetingCard` — it's already in the toolbar. The `greetingCard` `HStack` is fully replaced by the `ZStack` above.

**Step 2: Build and run in Simulator**

Expected: Home screen shows an animated running GIF as the greeting card background, with greeting text legible over it.

**Step 3: Commit**

```bash
git add PacePilot/PacePilot/Features/Home/HomeView.swift
git commit -m "feat: HomeView greetingCard as animated GIF hero background"
```

---

### Task 6: Add female runner banner to CommunityView

**Files:**
- Modify: `PacePilot/PacePilot/Features/Community/CommunityView.swift`

**What to change:** Add a `communityHeaderCard` computed var and insert it as the first `Section` in the `List`.

**Step 1: Add `communityHeaderCard` computed var**

Add this inside `CommunityView`, before `howItWorksSection`:

```swift
var communityHeaderCard: some View {
    ZStack(alignment: .bottomTrailing) {
        // Background gradient
        LinearGradient(
            colors: [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.35)],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Runner image - anchored to bottom trailing
        Image("RunnerFemale")
            .resizable()
            .scaledToFit()
            .frame(height: 145)
            .padding(.bottom, -4)

        // Text overlay on leading side
        VStack(alignment: .leading, spacing: 4) {
            Text("Run Together")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Your community, your pace.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: 160)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}
```

**Step 2: Insert as first section in the List**

In `body`, insert before `howItWorksSection`:

```swift
List {
    Section {
        communityHeaderCard
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
    }

    howItWorksSection
    // ... rest of sections
}
```

**Step 3: Build and run in Simulator**

Expected: CommunityView shows a green/accent gradient banner at the top with the female runner image on the right and "Run Together" text on the left.

**Step 4: Commit**

```bash
git add PacePilot/PacePilot/Features/Community/CommunityView.swift
git commit -m "feat: CommunityView female runner decorative banner"
```

---

### Task 7: Add male runner banner to RunDiscoveryView

**Files:**
- Modify: `PacePilot/PacePilot/Features/Races/RaceDiscoveryView.swift`

**What to change:** Add a `runsHeaderCard` computed var and insert it at the top of the view. Since the view uses a `Group` that switches between `ProgressView`, `emptyStateView`, and `List`, wrap the whole thing in a `VStack` or use a `List` with a leading section for the header.

**Step 1: Add `runsHeaderCard` computed var**

Add inside `RunDiscoveryView`:

```swift
var runsHeaderCard: some View {
    ZStack(alignment: .bottomTrailing) {
        // Dark charcoal gradient background
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.18, green: 0.18, blue: 0.28)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Runner image
        Image("RunnerMale")
            .resizable()
            .scaledToFit()
            .frame(height: 150)
            .padding(.bottom, -4)

        // Text overlay
        VStack(alignment: .leading, spacing: 4) {
            Text("Discover Runs")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Find your next group run.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: 160)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}
```

**Step 2: Update `body` to include the header above the list content**

The current `body` uses a `NavigationStack` with a `Group` inside. Wrap the `Group` and header together:

```swift
var body: some View {
    NavigationStack {
        // Always-visible header
        ScrollView {
            VStack(spacing: 0) {
                runsHeaderCard
                    .padding(.horizontal)
                    .padding(.top)

                Group {
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if displayedRuns.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(displayedRuns) { run in
                                NavigationLink(destination: RunDetailView(run: run, vm: vm)) {
                                    RunRow(run: run)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Runs")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !userCity.isEmpty {
                    Toggle(isOn: $filterByCity) {
                        Label("My City", systemImage: "location.fill")
                            .font(.caption)
                    }
                    .toggleStyle(.button)
                    .tint(.accentColor)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateRunView(vm: vm)
        }
        .task {
            userCity = AuthManager.shared.currentUser?.city ?? ""
            await vm.load()
        }
    }
}
```

Note: Switching from `List` to `ScrollView + LazyVStack` for the runs list is necessary to have the header always visible above the content. The visual appearance of rows stays the same.

**Step 3: Build and run in Simulator**

Expected: Runs tab shows a dark charcoal gradient banner at the top with the male runner image on the right and "Discover Runs" text on the left. Runs list scrolls below it.

**Step 4: Commit**

```bash
git add PacePilot/PacePilot/Features/Races/RaceDiscoveryView.swift
git commit -m "feat: RunDiscoveryView male runner decorative banner"
```

---

## Done

All three images are integrated. Build the app and verify:
- [ ] Home screen: animated GIF fills the greeting card, text readable over gradient
- [ ] Community tab: female runner banner at top, accent gradient
- [ ] Runs tab: male runner banner at top, dark gradient, list scrolls below
