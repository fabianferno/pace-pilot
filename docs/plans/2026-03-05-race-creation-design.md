# Race Creation Feature Design

**Date:** 2026-03-05
**Status:** Approved

## Overview

Add the ability for any authenticated user to create a race, surfaced via a `+` button modal sheet on the `RaceDiscoveryView`.

## Backend

### New endpoint
`POST /api/races` — JWT-protected, open to all authenticated users.

**Request body (Pydantic `CreateRaceRequest`):**
```json
{
  "name": "string",
  "distance_km": 42.2,
  "date": "2026-06-01T07:00:00Z",
  "location": "string",
  "registration_url": "string (optional)",
  "elevation_gain_meters": 120.0 (optional)
}
```

**Response:** created race document (same shape as `RaceDB`, serialized without `_id` alias).

### Files changed
- `pacepilot-server/db/repositories/race_repo.py` — add `create(data: dict) -> RaceDB`
- `pacepilot-server/services/race_service.py` — add `create(payload) -> RaceDB`
- `pacepilot-server/api/routes/races.py` — add `POST /` route with `CreateRaceRequest` schema

## iOS

### New file
- `PacePilot/Features/Races/CreateRaceView.swift` — `Form`-based sheet with fields:
  - Name (TextField, required)
  - Distance km (TextField numeric, required)
  - Date (DatePicker, required, minimum today)
  - Location (TextField, required)
  - Registration URL (TextField, optional)
  - Elevation Gain meters (TextField numeric, optional)
  - "Create Race" submit button; shows inline error on failure

### Files changed
- `RacesViewModel.swift` — add `createRace(name:distanceKm:date:location:registrationURL:elevationGainMeters:)` async method; prepends result to `races` on success
- `RaceDiscoveryView.swift` — add `@State var showCreate = false`; toolbar `+` button; `.sheet(isPresented:) { CreateRaceView(vm: vm) }`

## Data Flow

```
User taps + → CreateRaceView sheet
→ fills form → taps "Create Race"
→ vm.createRace(...) → POST /api/races
→ 201 response → new Race prepended to vm.races
→ sheet dismissed
```

## Error Handling

- Backend: returns 422 for missing/invalid fields (FastAPI default).
- iOS: catches thrown errors from `APIClient`, sets an `errorMessage` string displayed as inline text in the form.
