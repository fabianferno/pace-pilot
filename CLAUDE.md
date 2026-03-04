# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PacePilot is a voice-first AI running coach. This repo is in early development — the `PRD.md` is the source of truth for architecture, data models, API contracts, and feature specs.

## Architecture

Three separate components are developed in parallel:

### 1. Python Backend (`pacepilot-server/`)
- **FastAPI** server with REST endpoints, WebRTC signaling, and WebSocket handling
- **Pipecat** orchestrates the voice pipeline: Daily (WebRTC) transport → Gemini Live → back to client
- **Motor** (async MongoDB driver) via repository pattern under `db/repositories/`
- **Voice agent code** lives in `voice/`: pipeline definition, tool declarations, system prompts, and context processors
- Services (`services/`) contain business logic: plan generation, pace/HR zone calculation, Strava sync, calendar sync

### 2. iOS App (`PacePilot/`)
- **Swift/UIKit + SwiftUI**, minimum iOS 17
- Feature-organized under `Features/` (Onboarding, Home, Plan, ActiveRun, PostRun, Community, Races, Profile, History)
- `Core/` holds networking (`APIClient`, `WebRTCClient`), services (HealthKit, Location, WatchConnectivity), and models
- Voice session lifecycle managed by `VoiceSessionService` — it requests a Daily room/token from the backend, then connects via WebRTC
- During active runs, biometrics are streamed to the server every 5 seconds via `POST /api/voice/biometrics`

### 3. Apple Watch App (`PacePilotWatch/`)
- **SwiftUI/WatchKit**, watchOS 10+
- Communicates with iOS app via `WatchConnectivity` using typed messages defined in `Shared/WatchMessages.swift`
- Streams biometrics (HR, pace, GPS) to phone every 3s; receives haptic trigger commands back

## Key Design Decisions

**Voice agent is server-side:** iOS streams audio via WebRTC (Daily transport) → Python server (Pipecat) → Gemini Live on Vertex AI. The iOS app never talks to Gemini directly.

**Biometric context injection:** A `RunContextProcessor` in the Pipecat pipeline injects real-time sensor data so Gemini tools (`get_current_biometrics`, `get_run_progress`) always return current values.

**Tool-first coaching:** All agent claims about pace, HR, and distance must come from tool calls. The active-run system prompt explicitly forbids guessing biometrics.

**Session types:** `onboarding | pre_run | active_run | post_run | general` — each has its own system prompt in `voice/system_prompts/`.

## Tech Stack

| Layer | Key Libraries |
|-------|--------------|
| Backend | FastAPI, Pipecat (`pipecat-ai[google,daily]`), motor, google-auth, python-jose |
| Voice AI | Gemini Live via Vertex AI: `gemini-2.5-flash-native-audio-preview-12-2025` |
| WebRTC | Daily.co (`DAILY_API_KEY` env var required) |
| Database | MongoDB (collections: users, training_plans, workouts, run_sessions, communities, leaderboards, races, agent_sessions) |
| iOS | Swift, HealthKit, CoreLocation, EventKit, WatchConnectivity |

## Backend Commands

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn main:app --reload

# Run with specific host/port
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Required Environment Variables

```env
MONGODB_URI=mongodb+srv://...
MONGODB_DB_NAME=pacepilot_db
GCP_PROJECT_ID=...
GCP_REGION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
DAILY_API_KEY=...
STRAVA_CLIENT_ID=...
STRAVA_CLIENT_SECRET=...
STRAVA_REDIRECT_URI=...
GOOGLE_CALENDAR_CLIENT_ID=...
GOOGLE_CALENDAR_CLIENT_SECRET=...
JWT_SECRET=...
APP_ENV=development
```

## Data Model Notes

- All IDs are MongoDB `ObjectId`
- Pace stored as `float` seconds-per-km; format with `utils/formatters.py`
- `run_sessions.biometric_stream` stores the full sensor timeseries per run
- `training_plans.pace_zones` and `.hr_zones` are derived from the user's benchmark time using Daniels' VDOT tables (implemented in `services/pace_calculator.py`)
- Community tier is recalculated weekly from average easy-run pace over the last 4 weeks

## Voice Tools Reference

16 tools are declared in `voice/tools/definitions.py` and passed to Gemini Live. Tool handlers live in `voice/tools/` split by domain: `biometric_tools.py`, `plan_tools.py`, `history_tools.py`, `social_tools.py`, `calendar_tools.py`, `race_tools.py`, `user_tools.py`.

## API Base Paths

`/api/auth`, `/api/users`, `/api/plans`, `/api/workouts`, `/api/runs`, `/api/communities`, `/api/races`, `/api/calendar`, `/api/strava`, `/api/voice`
