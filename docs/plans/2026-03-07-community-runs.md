# Community Runs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename "Races" to "Community Runs" and add map-based location picking, RSVP, city filtering, and a detail view.

**Architecture:** Backend renames `races` route/collection to `community_runs`, replaces `interested_user_ids` with `rsvp_user_ids`, adds `latitude`/`longitude`/`city` to the model, adds RSVP DELETE endpoint, and adds `city` to `UserDB`. iOS renames all Race types to CommunityRun, adds a MapKit location picker in the create flow, a detail view with a map snapshot and RSVP button, a city filter toggle, and a City field in Profile.

**Tech Stack:** FastAPI + Motor (Python backend), SwiftUI + MapKit + CoreLocation (iOS)

---

## Task 1: Update backend data model

**Files:**
- Modify: `pacepilot-server/db/models.py`

**Step 1: Replace `RaceDB` with `CommunityRunDB`**

In `db/models.py`, replace the entire `RaceDB` class (lines 163–175) with:

```python
class CommunityRunDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    name: str
    distance_km: float
    date: datetime
    location: str
    city: str
    latitude: float
    longitude: float
    rsvp_user_ids: List[str] = []

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
```

Also add `city: Optional[str] = None` to `UserDB` (after line 38, before `created_at`).

**Step 2: Verify the file is valid Python**

```bash
cd pacepilot-server && python -c "from db.models import CommunityRunDB, UserDB; print('ok')"
```
Expected: `ok`

**Step 3: Commit**

```bash
git add pacepilot-server/db/models.py
git commit -m "feat: replace RaceDB with CommunityRunDB, add city to UserDB"
```

---

## Task 2: Replace the race repository with a run repository

**Files:**
- Create: `pacepilot-server/db/repositories/run_repo.py`
- The old `race_repo.py` is superseded — do NOT delete it yet (done in Task 6 cleanup)

**Step 1: Create `run_repo.py`**

```python
from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import CommunityRunDB


def _aware(doc: dict) -> dict:
    return {
        k: v.replace(tzinfo=timezone.utc) if isinstance(v, datetime) and v.tzinfo is None else v
        for k, v in doc.items()
    }


class RunRepository:
    def __init__(self):
        self.col = get_db()["community_runs"]

    async def discover(self, limit: int = 50) -> List[CommunityRunDB]:
        query = {"date": {"$gte": datetime.now(timezone.utc)}}
        cursor = self.col.find(query).sort("date", 1).limit(limit)
        return [CommunityRunDB(**_aware(doc)) async for doc in cursor]

    async def get_by_id(self, run_id: str) -> Optional[CommunityRunDB]:
        doc = await self.col.find_one({"_id": ObjectId(run_id)})
        return CommunityRunDB(**_aware(doc)) if doc else None

    async def rsvp(self, run_id: str, user_id: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(run_id)},
            {"$addToSet": {"rsvp_user_ids": user_id}}
        )

    async def unrsvp(self, run_id: str, user_id: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(run_id)},
            {"$pull": {"rsvp_user_ids": user_id}}
        )

    async def create(self, data: dict) -> CommunityRunDB:
        result = await self.col.insert_one(data)
        doc = await self.col.find_one({"_id": result.inserted_id})
        if doc is None:
            raise RuntimeError(f"Run not found after insert (id={result.inserted_id})")
        return CommunityRunDB(**_aware(doc))
```

**Step 2: Verify import**

```bash
cd pacepilot-server && python -c "from db.repositories.run_repo import RunRepository; print('ok')"
```
Expected: `ok`

**Step 3: Commit**

```bash
git add pacepilot-server/db/repositories/run_repo.py
git commit -m "feat: add RunRepository for community_runs collection"
```

---

## Task 3: Replace race service with run service

**Files:**
- Create: `pacepilot-server/services/run_service.py`

**Step 1: Create `run_service.py`**

```python
from db.repositories.run_repo import RunRepository
from db.models import CommunityRunDB
from typing import List, Optional


class RunService:
    def __init__(self):
        self.repo = RunRepository()

    async def discover(self) -> List[CommunityRunDB]:
        return await self.repo.discover()

    async def get(self, run_id: str) -> Optional[CommunityRunDB]:
        return await self.repo.get_by_id(run_id)

    async def rsvp(self, run_id: str, user_id: str) -> None:
        await self.repo.rsvp(run_id, user_id)

    async def unrsvp(self, run_id: str, user_id: str) -> None:
        await self.repo.unrsvp(run_id, user_id)

    async def create(self, payload: dict) -> CommunityRunDB:
        return await self.repo.create(payload)
```

**Step 2: Verify**

```bash
cd pacepilot-server && python -c "from services.run_service import RunService; print('ok')"
```
Expected: `ok`

**Step 3: Commit**

```bash
git add pacepilot-server/services/run_service.py
git commit -m "feat: add RunService"
```

---

## Task 4: Replace races API route with runs route

**Files:**
- Create: `pacepilot-server/api/routes/community_runs.py`
- Modify: `pacepilot-server/main.py`

**Step 1: Create `api/routes/community_runs.py`**

```python
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from api.middleware.auth import get_current_user_id
from services.run_service import RunService

router = APIRouter()


class CreateRunRequest(BaseModel):
    name: str
    distance_km: float
    date: datetime
    location: str
    city: str
    latitude: float
    longitude: float


def _serialize(run, user_id: str) -> dict:
    d = run.model_dump(by_alias=False)
    d["rsvp_count"] = len(run.rsvp_user_ids)
    d["is_rsvpd_by_user"] = user_id in run.rsvp_user_ids
    return d


@router.get("/discover")
async def discover_runs(user_id: str = Depends(get_current_user_id)):
    svc = RunService()
    runs = await svc.discover()
    return [_serialize(r, user_id) for r in runs]


@router.post("", status_code=201)
async def create_run(body: CreateRunRequest, user_id: str = Depends(get_current_user_id)):
    svc = RunService()
    data = body.model_dump()
    data["rsvp_user_ids"] = []
    run = await svc.create(data)
    return _serialize(run, user_id)


@router.get("/{run_id}")
async def get_run(run_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RunService()
    run = await svc.get(run_id)
    return _serialize(run, user_id) if run else {}


@router.post("/{run_id}/rsvp", status_code=200)
async def rsvp(run_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RunService()
    await svc.rsvp(run_id, user_id)
    return {"ok": True}


@router.delete("/{run_id}/rsvp", status_code=200)
async def unrsvp(run_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RunService()
    await svc.unrsvp(run_id, user_id)
    return {"ok": True}
```

**Step 2: Update `main.py`**

Replace the races import and router line:

```python
# Remove:
from api.routes import auth, users, plans, workouts, runs, communities, races, calendar, strava, voice
app.include_router(races.router, prefix="/api/races", tags=["races"])

# Add/replace with:
from api.routes import auth, users, plans, workouts, runs, communities, community_runs, calendar, strava, voice
app.include_router(community_runs.router, prefix="/api/community-runs", tags=["community-runs"])
```

**Step 3: Verify server starts**

```bash
cd pacepilot-server && python -c "import main; print('ok')"
```
Expected: `ok`

**Step 4: Commit**

```bash
git add pacepilot-server/api/routes/community_runs.py pacepilot-server/main.py
git commit -m "feat: add /api/community-runs route with RSVP endpoints"
```

---

## Task 5: Add `city` to users PATCH endpoint

**Files:**
- Modify: `pacepilot-server/api/routes/users.py`

**Step 1: Add `city` to `UserUpdateRequest`**

In `UserUpdateRequest`, add after `preferred_days`:
```python
city: Optional[str] = None
```

**Step 2: Verify**

```bash
cd pacepilot-server && python -c "from api.routes.users import UserUpdateRequest; r = UserUpdateRequest(city='Chennai'); print(r.city)"
```
Expected: `Chennai`

**Step 3: Commit**

```bash
git add pacepilot-server/api/routes/users.py
git commit -m "feat: add city field to user profile update"
```

---

## Task 6: Update voice race tools to use run service

**Files:**
- Modify: `pacepilot-server/voice/tools/race_tools.py`

**Step 1: Update `race_tools.py` to use `RunService`**

Replace the entire file content:

```python
from services.run_service import RunService


async def find_local_runs(user_id: str, **kwargs) -> list:
    svc = RunService()
    runs = await svc.discover()
    return [
        {
            "name": r.name,
            "distance_km": r.distance_km,
            "date": r.date.strftime("%B %d, %Y"),
            "location": r.location,
            "city": r.city,
            "rsvp_count": len(r.rsvp_user_ids),
        }
        for r in runs[:5]
    ]
```

**Step 2: Check if `race_tools.py` is referenced in voice tool definitions and update the function name**

```bash
grep -r "find_local_races\|race_tools" pacepilot-server/voice/
```

Update any references from `find_local_races` to `find_local_runs` in `voice/tools/definitions.py` or wherever tools are registered.

**Step 3: Commit**

```bash
git add pacepilot-server/voice/tools/race_tools.py
git commit -m "feat: update voice race tools to use RunService"
```

---

## Task 7: iOS — rename `Race` model to `CommunityRun`

**Files:**
- Modify: `PacePilot/PacePilot/Core/Models/Race.swift`

**Step 1: Replace file content**

Replace the entire `Race.swift` content:

```swift
import Foundation

struct CommunityRun: Codable, Identifiable {
    let id: String
    let name: String
    let distanceKm: Double
    let date: Date
    let location: String
    let city: String
    let latitude: Double
    let longitude: Double
    let rsvpCount: Int
    var isRsvpdByUser: Bool
}
```

The file can stay named `Race.swift` for now (Xcode doesn't require filename == type name), or rename it — either is fine. To rename in Xcode: right-click the file → Rename. If renaming, update the filename to `CommunityRun.swift`.

**Step 2: Build to see all compiler errors**

In Xcode: Cmd+B. Expect errors in `RacesViewModel.swift`, `RaceDiscoveryView.swift`, `CreateRaceView.swift`, `PacePilotApp.swift`. These are fixed in subsequent tasks.

**Step 3: Commit**

```bash
git add "PacePilot/PacePilot/Core/Models/Race.swift"
git commit -m "feat: replace Race model with CommunityRun"
```

---

## Task 8: iOS — add `city` to `User` model and `ProfileUpdateRequest`

**Files:**
- Modify: `PacePilot/PacePilot/Core/Models/User.swift`
- Modify: `PacePilot/PacePilot/Features/Profile/ProfileViewModel.swift`

**Step 1: Add `city` to `User`**

In `User.swift`, add after `preferredDays`:
```swift
var city: String?
```

**Step 2: Add `city` to `ProfileUpdateRequest`**

In `ProfileViewModel.swift`, add to `ProfileUpdateRequest`:
```swift
let city: String?
```

**Step 3: Commit**

```bash
git add "PacePilot/PacePilot/Core/Models/User.swift" \
        "PacePilot/PacePilot/Features/Profile/ProfileViewModel.swift"
git commit -m "feat: add city field to User model and ProfileUpdateRequest"
```

---

## Task 9: iOS — update Profile UI to include City field

**Files:**
- Modify: `PacePilot/PacePilot/Features/Profile/ProfileView.swift`

**Step 1: Add city state variable**

At the top of `ProfileView`, alongside other `@State` vars, add:
```swift
@State private var city = ""
```

**Step 2: Add city field to `personalSection`**

Inside `personalSection`, after the Name `HStack`:
```swift
HStack {
    Text("City")
    Spacer()
    TextField("Your city", text: $city)
        .multilineTextAlignment(.trailing)
        .foregroundColor(.secondary)
}
```

**Step 3: Populate city in `populateForm()`**

Add inside `populateForm()`:
```swift
city = user.city ?? ""
```

**Step 4: Include city in `saveChanges()`**

In the `ProfileUpdateRequest` initializer inside `saveChanges()`, add:
```swift
city: city.isEmpty ? nil : city,
```

**Step 5: Build and verify Profile section shows City field**

Cmd+B — expect no errors.

**Step 6: Commit**

```bash
git add "PacePilot/PacePilot/Features/Profile/ProfileView.swift"
git commit -m "feat: add city field to profile edit form"
```

---

## Task 10: iOS — rewrite `RunsViewModel` (was `RacesViewModel`)

**Files:**
- Modify: `PacePilot/PacePilot/Features/Races/RacesViewModel.swift`

**Step 1: Replace entire file content**

```swift
import Foundation

@MainActor
final class RunsViewModel: ObservableObject {
    @Published var runs: [CommunityRun] = []
    @Published var isLoading = false
    private let api: APIClient

    init(api: APIClient = .shared) { self.api = api }

    func load() async {
        isLoading = true
        runs = (try? await api.get("/api/community-runs/discover")) ?? []
        isLoading = false
    }

    func rsvp(_ runId: String) async {
        struct Empty: Decodable {}
        struct EmptyBody: Encodable {}
        _ = try? await api.post("/api/community-runs/\(runId)/rsvp", body: EmptyBody()) as Empty
        if let idx = runs.firstIndex(where: { $0.id == runId }) {
            runs[idx].isRsvpdByUser = true
            runs[idx].rsvpCount += 1  // Note: rsvpCount is let — change to var in CommunityRun
        }
    }

    func unrsvp(_ runId: String) async {
        struct Empty: Decodable {}
        _ = try? await api.delete("/api/community-runs/\(runId)/rsvp") as Empty
        if let idx = runs.firstIndex(where: { $0.id == runId }) {
            runs[idx].isRsvpdByUser = false
            runs[idx].rsvpCount = max(0, runs[idx].rsvpCount - 1)
        }
    }

    func createRun(
        name: String,
        distanceKm: Double,
        date: Date,
        location: String,
        city: String,
        latitude: Double,
        longitude: Double
    ) async throws {
        struct Body: Encodable {
            let name: String
            let distanceKm: Double
            let date: Date
            let location: String
            let city: String
            let latitude: Double
            let longitude: Double
        }
        let body = Body(
            name: name, distanceKm: distanceKm, date: date,
            location: location, city: city,
            latitude: latitude, longitude: longitude
        )
        let created: CommunityRun = try await api.post("/api/community-runs", body: body)
        runs.insert(created, at: 0)
    }
}
```

> Note: `rsvpCount` needs to be `var` in `CommunityRun` for optimistic update. Go back to `CommunityRun.swift` and change `let rsvpCount` → `var rsvpCount`.

Also check if `APIClient` has a `delete` method. If not, you will need to add it — see Task 11.

**Step 2: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/RacesViewModel.swift"
git commit -m "feat: rewrite RacesViewModel as RunsViewModel with RSVP support"
```

---

## Task 11: iOS — add `delete` method to `APIClient` if missing

**Files:**
- Modify: `PacePilot/PacePilot/Core/Networking/APIClient.swift` (check actual path with Glob)

**Step 1: Check if `delete` exists**

```bash
grep -n "func delete" PacePilot/PacePilot/Core/Networking/APIClient.swift
```

If it doesn't exist, add it alongside the existing `post`/`patch` methods:

```swift
func delete<T: Decodable>(_ path: String) async throws -> T {
    let request = try buildRequest(path: path, method: "DELETE", body: Optional<EmptyBody>.none)
    let (data, response) = try await URLSession.shared.data(for: request)
    try validateResponse(response, data: data)
    return try decoder.decode(T.self, from: data)
}
```

(Adapt to match the existing `buildRequest`/`validateResponse` pattern in the file.)

**Step 2: Build — Cmd+B**

**Step 3: Commit if changed**

```bash
git add "PacePilot/PacePilot/Core/Networking/APIClient.swift"
git commit -m "feat: add delete method to APIClient"
```

---

## Task 12: iOS — create `RunDetailView`

**Files:**
- Create: `PacePilot/PacePilot/Features/Races/RunDetailView.swift`

**Step 1: Create the file**

```swift
import SwiftUI
import MapKit

struct RunDetailView: View {
    let run: CommunityRun
    @ObservedObject var vm: RunsViewModel
    @Environment(\.dismiss) private var dismiss

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: run.latitude, longitude: run.longitude)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))) {
                    Marker(run.name, coordinate: coordinate)
                }
                .frame(height: 220)
                .disabled(true)

                VStack(alignment: .leading, spacing: 16) {
                    Text(run.name)
                        .font(.title2.bold())

                    HStack(spacing: 20) {
                        Label(String(format: "%.0f km", run.distanceKm), systemImage: "ruler")
                        Label(run.city, systemImage: "mappin")
                        Label(run.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Label(run.location, systemImage: "location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                        Text("\(run.rsvpCount) going")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)

                    Divider()

                    // RSVP button
                    let isGoing = vm.runs.first(where: { $0.id == run.id })?.isRsvpdByUser ?? run.isRsvpdByUser
                    Button(action: {
                        Task {
                            if isGoing {
                                await vm.unrsvp(run.id)
                            } else {
                                await vm.rsvp(run.id)
                            }
                        }
                    }) {
                        Label(isGoing ? "Can't Go" : "Going", systemImage: isGoing ? "xmark.circle" : "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isGoing ? Color(.systemGray5) : Color.accentColor)
                            .foregroundColor(isGoing ? .primary : .black)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .navigationTitle("Run Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Step 2: Build — Cmd+B**

**Step 3: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/RunDetailView.swift"
git commit -m "feat: add RunDetailView with map and RSVP button"
```

---

## Task 13: iOS — create location picker for `CreateRunView`

**Files:**
- Create: `PacePilot/PacePilot/Features/Races/LocationPickerView.swift`

**Step 1: Create the file**

```swift
import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: (CLLocationCoordinate2D, String, String) -> Void
    // onSelect(coordinate, displayLocation, city)

    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocation = ""
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search for a place", text: $query)
                        .onSubmit { Task { await search() } }
                    if isSearching {
                        ProgressView().scaleEffect(0.7)
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                if !results.isEmpty && selectedCoordinate == nil {
                    List(results, id: \.self) { item in
                        Button(action: { select(item) }) {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Unknown").font(.body)
                                if let addr = item.placemark.title {
                                    Text(addr).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } else if let coord = selectedCoordinate {
                    Map(position: $cameraPosition) {
                        Marker(selectedLocation, coordinate: coord)
                    }
                    .frame(maxHeight: .infinity)

                    Button("Confirm Location") {
                        Task { await confirmLocation(coord) }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedCoordinate != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            selectedCoordinate = nil
                            results = []
                        }
                    }
                }
            }
        }
    }

    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        results = (try? await search.start())?.mapItems ?? []
        isSearching = false
    }

    private func select(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        selectedCoordinate = coord
        selectedLocation = item.name ?? query
        cameraPosition = .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        results = []
    }

    private func confirmLocation(_ coord: CLLocationCoordinate2D) async {
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(loc)
        let city = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea ?? "Unknown"
        dismiss()
        onSelect(coord, selectedLocation, city)
    }
}
```

**Step 2: Build — Cmd+B**

**Step 3: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/LocationPickerView.swift"
git commit -m "feat: add LocationPickerView with MKLocalSearch and reverse geocoding"
```

---

## Task 14: iOS — rewrite `CreateRunView`

**Files:**
- Modify: `PacePilot/PacePilot/Features/Races/CreateRaceView.swift`

**Step 1: Replace entire file content**

```swift
import SwiftUI
import MapKit

struct CreateRunView: View {
    @ObservedObject var vm: RunsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var distanceKmText = ""
    @State private var date = Date()
    @State private var locationDisplay = ""
    @State private var city = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var showLocationPicker = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(distanceKmText) != nil &&
        latitude != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Run Details") {
                    TextField("Name", text: $name)
                    TextField("Distance (km)", text: $distanceKmText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, in: Date()..., displayedComponents: .date)
                }
                Section("Location") {
                    Button(action: { showLocationPicker = true }) {
                        HStack {
                            Label(
                                locationDisplay.isEmpty ? "Pick on Map" : locationDisplay,
                                systemImage: "mappin.and.ellipse"
                            )
                            .foregroundColor(locationDisplay.isEmpty ? .accentColor : .primary)
                            Spacer()
                            if !locationDisplay.isEmpty {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    if !city.isEmpty {
                        LabeledContent("City", value: city)
                            .foregroundColor(.secondary)
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("New Run")
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
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView { coord, display, resolvedCity in
                    latitude = coord.latitude
                    longitude = coord.longitude
                    locationDisplay = display
                    city = resolvedCity
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        guard let distanceKm = Double(distanceKmText),
              let lat = latitude, let lng = longitude else { return }
        do {
            try await vm.createRun(
                name: name.trimmingCharacters(in: .whitespaces),
                distanceKm: distanceKm,
                date: date,
                location: locationDisplay,
                city: city,
                latitude: lat,
                longitude: lng
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

**Step 2: Build — Cmd+B**

**Step 3: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/CreateRaceView.swift"
git commit -m "feat: rewrite CreateRaceView as CreateRunView with map location picker"
```

---

## Task 15: iOS — rewrite `RunDiscoveryView` with city filter and detail navigation

**Files:**
- Modify: `PacePilot/PacePilot/Features/Races/RaceDiscoveryView.swift`

**Step 1: Replace entire file content**

```swift
import SwiftUI

struct RunDiscoveryView: View {
    @StateObject private var vm = RunsViewModel()
    @State private var showCreate = false
    @State private var filterByCity = false
    // Read user city from AuthManager or a simple UserDefaults cache
    @State private var userCity: String = AuthManager.shared.currentUser?.city ?? ""

    private var displayedRuns: [CommunityRun] {
        guard filterByCity, !userCity.isEmpty else { return vm.runs }
        return vm.runs.filter { $0.city.lowercased() == userCity.lowercased() }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayedRuns.isEmpty {
                    emptyStateView
                } else {
                    List(displayedRuns) { run in
                        NavigationLink(destination: RunDetailView(run: run, vm: vm)) {
                            RunRow(run: run)
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
            .task { await vm.load() }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.accentColor.opacity(0.8))
            VStack(spacing: 8) {
                Text(filterByCity ? "No Runs in \(userCity)" : "No Runs Yet")
                    .font(.title2.bold())
                Text(filterByCity
                     ? "No upcoming community runs in your city. Try showing all runs."
                     : "Be the first to host a community run!")
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

private struct RunRow: View {
    let run: CommunityRun

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(run.name).font(.headline)
                Spacer()
                if run.isRsvpdByUser {
                    Label("Going", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                }
            }
            HStack(spacing: 12) {
                Label(String(format: "%.0f km", run.distanceKm), systemImage: "ruler")
                Label(run.city, systemImage: "mappin")
                Label(run.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
            }
            .font(.caption).foregroundColor(.secondary)
            if run.rsvpCount > 0 {
                Text("\(run.rsvpCount) going")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

**Note:** `AuthManager.shared.currentUser?.city` requires `city` to be on the `User` model (done in Task 8). If `AuthManager.currentUser` is computed from a stored token and doesn't cache the full `User` object, you may need to load it from `UserDefaults` or a simple in-memory store. Check `AuthManager` implementation and adapt accordingly.

**Step 2: Update tab label in `PacePilotApp.swift`**

Change the tab item for `RaceDiscoveryView` → `RunDiscoveryView`:

```swift
// Replace:
RaceDiscoveryView()
    .tabItem { Label("Races", systemImage: "flag.checkered") }

// With:
RunDiscoveryView()
    .tabItem { Label("Runs", systemImage: "figure.run") }
```

**Step 3: Build — Cmd+B. Fix any remaining compiler errors.**

**Step 4: Commit**

```bash
git add "PacePilot/PacePilot/Features/Races/RaceDiscoveryView.swift" \
        "PacePilot/PacePilot/PacePilotApp.swift"
git commit -m "feat: rewrite RunDiscoveryView with city filter, detail navigation, and RSVP badges"
```

---

## Task 16: Final cleanup

**Files:**
- Delete (optional): `pacepilot-server/api/routes/races.py`, `pacepilot-server/services/race_service.py`, `pacepilot-server/db/repositories/race_repo.py`

**Step 1: Confirm nothing imports the old race modules**

```bash
grep -r "from api.routes.races\|from services.race_service\|from db.repositories.race_repo\|import races" pacepilot-server/
```

If nothing imports them, delete them:

```bash
rm pacepilot-server/api/routes/races.py \
   pacepilot-server/services/race_service.py \
   pacepilot-server/db/repositories/race_repo.py
```

**Step 2: Full server smoke test**

```bash
cd pacepilot-server && python -c "import main; print('server ok')"
```

**Step 3: Full iOS build**

In Xcode: Cmd+B. Expect 0 errors.

**Step 4: Commit**

```bash
git add -u
git commit -m "chore: remove legacy race files replaced by community runs"
```
