# Race Creation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow any authenticated user to create a race via `POST /api/races` (backend) and a modal sheet form on `RaceDiscoveryView` (iOS).

**Architecture:** Backend adds a `CreateRaceRequest` Pydantic schema + `create()` method through repo → service → route. iOS adds a `CreateRaceView` sheet, a `createRace()` method on `RacesViewModel`, and a `+` toolbar button on `RaceDiscoveryView`.

**Tech Stack:** FastAPI + Pydantic + Motor (backend); SwiftUI + `APIClient` (iOS)

---

### Task 1: Backend — `race_repo.py` create method

**Files:**
- Modify: `pacepilot-server/db/repositories/race_repo.py`

**Step 1: Add `create` method to `RaceRepository`**

Open `pacepilot-server/db/repositories/race_repo.py` and append this method inside `RaceRepository`:

```python
async def create(self, data: dict) -> RaceDB:
    result = await self.col.insert_one(data)
    doc = await self.col.find_one({"_id": result.inserted_id})
    return RaceDB(**doc)
```

**Step 2: Verify file looks correct**

Run: `cat pacepilot-server/db/repositories/race_repo.py`
Expected: file contains `async def create(self, data: dict) -> RaceDB:`

**Step 3: Commit**

```bash
git add pacepilot-server/db/repositories/race_repo.py
git commit -m "feat: add create method to RaceRepository"
```

---

### Task 2: Backend — `race_service.py` create method

**Files:**
- Modify: `pacepilot-server/services/race_service.py`

**Step 1: Add `create` method to `RaceService`**

Open `pacepilot-server/services/race_service.py` and append:

```python
async def create(self, payload: dict) -> RaceDB:
    return await self.repo.create(payload)
```

**Step 2: Commit**

```bash
git add pacepilot-server/services/race_service.py
git commit -m "feat: add create method to RaceService"
```

---

### Task 3: Backend — `POST /api/races` route

**Files:**
- Modify: `pacepilot-server/api/routes/races.py`

**Step 1: Add `CreateRaceRequest` schema and POST route**

Replace the contents of `pacepilot-server/api/routes/races.py` with:

```python
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from api.middleware.auth import get_current_user_id
from services.race_service import RaceService

router = APIRouter()


class CreateRaceRequest(BaseModel):
    name: str
    distance_km: float
    date: datetime
    location: str
    registration_url: Optional[str] = None
    elevation_gain_meters: Optional[float] = None


@router.get("/discover")
async def discover_races(
    distance_km: Optional[float] = Query(None),
    user_id: str = Depends(get_current_user_id),
):
    svc = RaceService()
    races = await svc.discover(distance_km=distance_km)
    return [
        {**r.model_dump(by_alias=False), "is_interested_by_user": user_id in r.interested_user_ids}
        for r in races
    ]


@router.post("")
async def create_race(
    body: CreateRaceRequest,
    user_id: str = Depends(get_current_user_id),
):
    svc = RaceService()
    data = body.model_dump()
    data["interested_user_ids"] = []
    race = await svc.create(data)
    return {**race.model_dump(by_alias=False), "is_interested_by_user": False}


@router.get("/{race_id}")
async def get_race(race_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RaceService()
    race = await svc.get(race_id)
    return race.model_dump(by_alias=False) if race else {}


@router.post("/{race_id}/register-interest")
async def register_interest(race_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RaceService()
    await svc.register_interest(race_id, user_id)
    return {"ok": True}
```

**Step 2: Verify the server starts without errors**

```bash
cd pacepilot-server
uvicorn main:app --reload &
sleep 3
curl -s http://localhost:8000/health
kill %1
```
Expected: `{"status":"ok","service":"pacepilot-api"}`

**Step 3: Commit**

```bash
git add pacepilot-server/api/routes/races.py
git commit -m "feat: add POST /api/races endpoint for race creation"
```

---

### Task 4: iOS — `createRace` method on `RacesViewModel`

**Files:**
- Modify: `PacePilot/PacePilot/Features/Races/RacesViewModel.swift`

**Step 1: Add `CreateRaceBody` and `createRace` to `RacesViewModel`**

Replace the full contents of `PacePilot/PacePilot/Features/Races/RacesViewModel.swift` with:

```swift
import Foundation
import Combine

@MainActor
final class RacesViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var isLoading = false
    private let api: APIClient
    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        races = (try? await api.get("/api/races/discover")) ?? []
        isLoading = false
    }

    func markInterest(_ raceId: String) async {
        struct Empty: Decodable {}
        struct EmptyBody: Encodable {}
        _ = try? await api.post("/api/races/\(raceId)/register-interest", body: EmptyBody()) as Empty
        if let idx = races.firstIndex(where: { $0.id == raceId }) {
            races[idx].isInterestedByUser = true
        }
    }

    func createRace(
        name: String,
        distanceKm: Double,
        date: Date,
        location: String,
        registrationURL: String?,
        elevationGainMeters: Double?
    ) async throws {
        struct Body: Encodable {
            let name: String
            let distanceKm: Double
            let date: Date
            let location: String
            let registrationUrl: String?
            let elevationGainMeters: Double?
        }
        let body = Body(
            name: name,
            distanceKm: distanceKm,
            date: date,
            location: location,
            registrationUrl: registrationURL,
            elevationGainMeters: elevationGainMeters
        )
        let created: Race = try await api.post("/api/races", body: body)
        races.insert(created, at: 0)
    }
}
```

**Step 2: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/RacesViewModel.swift"
git commit -m "feat: add createRace method to RacesViewModel"
```

---

### Task 5: iOS — `CreateRaceView.swift`

**Files:**
- Create: `PacePilot/PacePilot/Features/Races/CreateRaceView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct CreateRaceView: View {
    @ObservedObject var vm: RacesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var distanceKmText = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var registrationURL = ""
    @State private var elevationText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(distanceKmText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Race Details") {
                    TextField("Name", text: $name)
                    TextField("Distance (km)", text: $distanceKmText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, in: Date()..., displayedComponents: .date)
                    TextField("Location", text: $location)
                }
                Section("Optional") {
                    TextField("Registration URL", text: $registrationURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Elevation Gain (m)", text: $elevationText)
                        .keyboardType(.decimalPad)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Race")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { Task { await submit() } }
                        .disabled(!isValid || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await vm.createRace(
                name: name.trimmingCharacters(in: .whitespaces),
                distanceKm: Double(distanceKmText) ?? 0,
                date: date,
                location: location.trimmingCharacters(in: .whitespaces),
                registrationURL: registrationURL.isEmpty ? nil : registrationURL,
                elevationGainMeters: elevationText.isEmpty ? nil : Double(elevationText)
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
```

**Step 2: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/CreateRaceView.swift"
git commit -m "feat: add CreateRaceView sheet"
```

---

### Task 6: iOS — Wire `+` button in `RaceDiscoveryView`

**Files:**
- Modify: `PacePilot/PacePilot/Features/Races/RaceDiscoveryView.swift`

**Step 1: Add `showCreate` state and toolbar button**

Replace the full file contents with:

```swift
import SwiftUI

struct RaceDiscoveryView: View {
    @StateObject private var vm = RacesViewModel()
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.races.isEmpty {
                    emptyStateView
                } else {
                    List(vm.races) { race in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(race.name).font(.headline)
                                Spacer()
                                if race.isInterestedByUser {
                                    Image(systemName: "star.fill").foregroundColor(.accentColor)
                                }
                            }
                            HStack(spacing: 12) {
                                Label(String(format: "%.0f km", race.distanceKm), systemImage: "ruler")
                                Label(race.location, systemImage: "mappin")
                                Label(race.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            }
                            .font(.caption).foregroundColor(.secondary)
                        }
                        .swipeActions {
                            if !race.isInterestedByUser {
                                Button("Interested") { Task { await vm.markInterest(race.id) } }
                                    .tint(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Races")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateRaceView(vm: vm)
            }
            .task { await vm.load() }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "flag.checkered")
                .font(.system(size: 60))
                .foregroundColor(.accentColor.opacity(0.8))
            VStack(spacing: 8) {
                Text("No Races Yet")
                    .font(.title2.bold())
                Text("Upcoming races will appear here once they're added. Check back soon to discover events near you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**Step 2: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/RaceDiscoveryView.swift"
git commit -m "feat: wire CreateRaceView sheet to RaceDiscoveryView toolbar"
```
