# Runner Images Integration — Design Doc

Date: 2026-03-07

## Overview

Integrate three runner images across the PacePilot iOS app:
- `artistic-runner.gif` → HomeView greeting card hero background
- `female-runner-transparent-bg-medium-stride.png` → CommunityView decorative banner
- `male-runner-transparent-bg-long-stride.png` → RunDiscoveryView decorative banner

## Asset Management

### PNG Images → Assets.xcassets
Create two new imagesets in `PacePilot/PacePilot/Assets.xcassets/`:
- `RunnerFemale.imageset/` — contains `female-runner-transparent-bg-medium-stride.png` + `Contents.json`
- `RunnerMale.imageset/` — contains `male-runner-transparent-bg-long-stride.png` + `Contents.json`

Reference in SwiftUI as `Image("RunnerFemale")` and `Image("RunnerMale")`.

### GIF → Bundle Resource
`artistic-runner.gif` is added as a Copy Bundle Resource in the Xcode project (not an imageset — UIKit requires raw data for GIF animation). Referenced via `Bundle.main.url(forResource: "artistic-runner", withExtension: "gif")`.

The GIF file is copied into `PacePilot/PacePilot/Resources/` (new folder) and added to the project's bundle resources in `project.pbxproj`.

## Components

### GIFImageView (new shared utility)
File: `PacePilot/PacePilot/Core/Views/GIFImageView.swift`

A `UIViewRepresentable` wrapping `UIImageView`:
- Loads GIF data from `Bundle.main`
- Uses `UIImage.animatedImage(withAnimatedGIFData:)` to extract frames
- Sets `imageView.animationImages`, `imageView.animationDuration`, and calls `startAnimating()`
- `contentMode = .scaleAspectFill`
- `clipsToBounds = true`

### HomeView — greetingCard (modified)
Replace the current `HStack` card with a `ZStack` card:
- Height: ~180pt, full width, `cornerRadius(16)`
- Layer 1 (bottom): `GIFImageView(name: "artistic-runner")` — `.scaleAspectFill`, clipped
- Layer 2: Linear gradient overlay — `.black.opacity(0.45)` to `.clear`, direction bottom-to-top
- Layer 3 (top): `VStack(alignment: .leading)` with greeting text in `.white` / `.white.opacity(0.8)`

Remove the `AppLogo` image from greetingCard (it stays in the toolbar only).

### CommunityView — communityHeaderCard (new)
A new computed var `communityHeaderCard: some View`:
- `ZStack(alignment: .bottomTrailing)` card, height ~160pt, `cornerRadius(16)`
- Background: `LinearGradient` from `Color.accentColor.opacity(0.85)` to `Color.accentColor.opacity(0.4)`, leading-to-trailing
- `Image("RunnerFemale")` — `.resizable()`, `.scaledToFit()`, frame height 145pt, trailing/bottom aligned, slight negative bottom padding to let feet bleed to edge
- Leading text overlay: `VStack(alignment: .leading)` — "Run Together" (title2.bold, white) + "Your community, your pace." (caption, white.opacity(0.8))
- Inserted as first `Section` in the `List` (no section title, no separators via `.listRowInsets` / `.listRowBackground`)

### RunDiscoveryView — runsHeaderCard (new)
A new computed var `runsHeaderCard: some View` on `RunDiscoveryView`:
- Same `ZStack(alignment: .bottomTrailing)` card pattern, height ~160pt
- Background: `LinearGradient` from `Color(red: 0.1, green: 0.1, blue: 0.15)` to `Color(red: 0.2, green: 0.2, blue: 0.3)` (dark charcoal)
- `Image("RunnerMale")` — `.resizable()`, `.scaledToFit()`, frame height 150pt, trailing/bottom aligned
- Leading text: "Discover Runs" (title2.bold, white) + "Find your next group run." (caption, white.opacity(0.8))
- Inserted above the `Group` in the NavigationStack body, inside a `VStack` or as a `List` header section

## File Changes Summary

| File | Change |
|------|--------|
| `Assets.xcassets/RunnerFemale.imageset/` | New imageset |
| `Assets.xcassets/RunnerMale.imageset/` | New imageset |
| `Resources/artistic-runner.gif` | New bundle resource (copied from app-images/) |
| `Core/Views/GIFImageView.swift` | New UIViewRepresentable |
| `project.pbxproj` | Add GIF to Copy Bundle Resources + new swift/image file references |
| `Features/Home/HomeView.swift` | Rewrite greetingCard as ZStack hero |
| `Features/Community/CommunityView.swift` | Add communityHeaderCard section |
| `Features/Races/RaceDiscoveryView.swift` | Add runsHeaderCard, wrap body in VStack |

## Non-Goals
- No changes to Watch app
- No changes to backend
- No third-party dependencies added
