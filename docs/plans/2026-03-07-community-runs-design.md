# Community Runs — Design Doc
Date: 2026-03-07

## Overview

Rename the "Races" feature to "Community Runs" — a place for users to host and join group runs. Adds map-based location picking, RSVP, city-based filtering, and a detail view.

## Data Model Changes

### Backend: `RaceDB` → `CommunityRunDB` (collection: `community_runs`)

| Field | Change |
|---|---|
| `name` | unchanged |
| `distance_km` | unchanged |
| `date` | unchanged |
| `location` | unchanged (display string) |
| `city` | **new** — plain string, auto-populated from reverse geocode on iOS |
| `latitude` | **new** — float |
| `longitude` | **new** — float |
| `rsvp_user_ids` | **renamed** from `interested_user_ids` |
| `registration_url` | **removed** |
| `elevation_gain_meters` | **removed** |

### Backend: `UserDB`

- Add `city: Optional[str] = None`

### iOS: `Race.swift` → `CommunityRun.swift`

- `isRsvpdByUser: Bool` (replaces `isInterestedByUser`)
- Add `latitude`, `longitude`, `city`
- Remove `registrationUrl`, `elevationGainMeters`

## API Changes

Route prefix: `/api/races` → `/api/runs`

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/runs/discover` | List upcoming runs (all cities) |
| `POST` | `/api/runs` | Create a run |
| `GET` | `/api/runs/{run_id}` | Get run detail with `rsvp_count` + `is_rsvpd_by_user` |
| `POST` | `/api/runs/{run_id}/rsvp` | RSVP (add user to `rsvp_user_ids`) |
| `DELETE` | `/api/runs/{run_id}/rsvp` | Un-RSVP |

`POST /api/runs` body: `name`, `distance_km`, `date`, `latitude`, `longitude`, `city`

User profile `PATCH /api/users/me` gains `city` field support.

## iOS UI

### Runs List (`RunDiscoveryView`)
- Segmented control or toggle: "All" | "My City"
- "My City" filters client-side: `run.city.lowercased() == user.city.lowercased()`
- Row shows: name, distance, date, city, attendee count, "Going" badge if RSVPd
- Tap row → `RunDetailView`

### Run Detail View (`RunDetailView`)
- Non-interactive `Map` at top with annotation at run coordinates
- Name, date, distance, city, attendee count
- "Going" / "Can't Go" toggle button at bottom
- Calls `POST /DELETE /api/runs/{id}/rsvp`

### Create Run (`CreateRunView`)
- Fields: name, distance (km), date/time
- Location picker:
  1. Search bar using `MKLocalSearch`
  2. Tap result → map view with draggable pin
  3. On confirm, `CLGeocoder.reverseGeocodeLocation` extracts `city` from placemark
  4. Stores `latitude`, `longitude`, `city`

### Profile
- Add "City" text field to existing profile edit screen
- Saved to `UserDB.city` via `PATCH /api/users/me`

## Approach Decision

City filtering uses plain string matching (Option A). Filtering is client-side. No geocoding API required. City string is populated automatically from reverse geocode when the host drops a pin during run creation.

## Files to Change

**Backend:**
- `db/models.py` — rename/update `RaceDB`, add `city` to `UserDB`
- `db/repositories/race_repo.py` → `run_repo.py`
- `services/race_service.py` → `run_service.py`
- `api/routes/races.py` → `runs.py` (new endpoints: `rsvp` POST/DELETE)
- `main.py` — update route registration
- `voice/tools/race_tools.py` → `run_tools.py`

**iOS:**
- `Core/Models/Race.swift` → `CommunityRun.swift`
- `Features/Races/` → `Features/Runs/` (rename all files)
- `Features/Profile/ProfileView.swift` + `ProfileViewModel.swift` — add city field
- `App/AppRouter.swift` — update tab reference
- `PacePilotApp.swift` — update any references
