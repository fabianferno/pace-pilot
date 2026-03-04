# PacePilot Python Backend — Design Document

**Date:** 2026-03-05
**Status:** Approved
**Scope:** Full `pacepilot-server/` Python backend
**Root directory:** `pacepilot-server/` at repo root

---

## Architecture

FastAPI async server. Each request is handled by an async route handler → service layer → MongoDB repository. Voice pipeline runs as a persistent background asyncio task per active session.

```
iOS App (Daily WebRTC)
       │
       ▼
FastAPI (uvicorn) ──► Pipecat Pipeline ──► Gemini Live (Vertex AI)
       │                    │
       ▼                    ▼
  MongoDB (Motor)    Tool Handlers ──► MongoDB / external APIs
```

---

## Directory Structure

```
pacepilot-server/
├── main.py
├── requirements.txt
├── .env.example
├── config/
│   ├── settings.py            # Pydantic BaseSettings
│   └── gcp_auth.py            # Vertex AI token refresher
├── db/
│   ├── connection.py          # Motor singleton
│   ├── models.py              # Pydantic models (all collections)
│   └── repositories/
│       ├── user_repo.py
│       ├── plan_repo.py
│       ├── workout_repo.py
│       ├── run_repo.py
│       ├── community_repo.py
│       ├── race_repo.py
│       └── agent_session_repo.py
├── api/
│   ├── middleware/
│   │   └── auth.py            # JWT dependency: get_current_user
│   └── routes/
│       ├── auth.py            # /api/auth/apple, /refresh
│       ├── users.py           # /api/users/me, stats
│       ├── plans.py           # /api/plans/*
│       ├── workouts.py        # /api/workouts/*
│       ├── runs.py            # /api/runs/*
│       ├── communities.py     # /api/communities/*
│       ├── races.py           # /api/races/*
│       ├── calendar.py        # /api/calendar/*
│       ├── strava.py          # /api/strava/*
│       └── voice.py           # /api/voice/*
├── services/
│   ├── plan_engine.py
│   ├── pace_calculator.py
│   ├── community_service.py
│   ├── race_service.py
│   ├── strava_service.py
│   └── calendar_service.py
├── voice/
│   ├── pipeline.py
│   ├── session_manager.py
│   ├── context/
│   │   └── run_context_processor.py
│   ├── system_prompts/
│   │   ├── onboarding.py
│   │   ├── active_run.py
│   │   ├── post_run.py
│   │   └── general.py
│   └── tools/
│       ├── definitions.py
│       ├── biometric_tools.py
│       ├── plan_tools.py
│       ├── history_tools.py
│       ├── social_tools.py
│       ├── calendar_tools.py
│       ├── race_tools.py
│       └── user_tools.py
└── utils/
    ├── formatters.py
    ├── jwt_utils.py
    └── apple_auth.py
```

---

## Key Design Decisions

### Auth
- Apple identity token validated via Apple JWKS endpoint (`appleid.apple.com`)
- `python-jose` decodes token after fetching public key
- On success: issue HS256 JWT (24h access, 30d refresh) via `jwt_utils.py`
- `get_current_user` FastAPI dependency decodes Bearer token on every protected route

### Voice Pipeline
- `POST /api/voice/session` → Daily REST API creates a room → returns `room_url + token`
- Pipecat pipeline starts in background asyncio task: `DailyTransport → RunContextProcessor → GeminiLiveLLMService`
- `session_manager.py` tracks active pipelines by `session_id`
- `POST /api/voice/biometrics` → updates in-memory `BiometricStore[session_id]`
- `RunContextProcessor` intercepts tool calls and returns live values from `BiometricStore`
- `POST /api/voice/end` → stops pipeline, saves transcript to `agent_sessions` collection

### Training Plan Engine
- VDOT lookup table in `pace_calculator.py` (from Daniels' tables)
- Input: benchmark 5K or 10K time → VDOT → 5 pace zones (easy, marathon, threshold, interval, rep)
- HR zones from Karvonen formula (needs resting HR + max HR)
- `plan_engine.py` distributes workouts across preferred days using hard-easy principle
- Phases: Base → Build → Peak → Taper → Recovery

### Community Tiers
- Assigned on demand: query last 4 weeks of easy runs → compute average pace → map to tier
- Tiers: Discovery (>7:30/km), Foundation (6:00–7:30), Momentum (5:00–6:00), Velocity (4:00–5:00), Elite (<4:00)

### All 16 Voice Tools
Declared in `voice/tools/definitions.py` as Gemini function declarations.
Handlers split by domain:
- `biometric_tools`: get_current_biometrics, get_run_progress
- `plan_tools`: get_todays_workout, get_plan_status, generate_training_plan, reschedule_workout
- `history_tools`: get_recent_runs, get_personal_records, get_weekly_stats
- `social_tools`: get_friend_activity, get_leaderboard_position
- `calendar_tools`: schedule_run_to_calendar
- `race_tools`: find_local_races
- `user_tools`: update_user_profile, mark_not_feeling_well

---

## API Surface

All routes prefixed with `/api`.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/apple | No | Exchange Apple token for JWT |
| POST | /auth/refresh | No | Refresh JWT |
| GET | /users/me | Yes | Get profile |
| PATCH | /users/me | Yes | Update profile |
| GET | /users/me/stats | Yes | Weekly distance, runs |
| POST | /plans/generate | Yes | Generate training plan |
| GET | /plans/active | Yes | Get active plan |
| GET | /plans/{id}/workouts | Yes | List plan workouts |
| PATCH | /plans/{id} | Yes | Pause/adjust plan |
| GET | /workouts/today | Yes | Today's workout |
| GET | /workouts/week | Yes | Current week workouts |
| PATCH | /workouts/{id}/reschedule | Yes | Reschedule |
| PATCH | /workouts/{id}/skip | Yes | Skip |
| POST | /runs | Yes | Save completed run |
| GET | /runs | Yes | Run history (paginated) |
| GET | /runs/{id} | Yes | Run detail |
| GET | /runs/recent | Yes | N most recent runs |
| GET | /communities/me | Yes | User community + tier |
| GET | /communities/me/leaderboard | Yes | Leaderboard |
| GET | /communities/{id}/challenges | Yes | Challenges |
| GET | /communities/friends/activity | Yes | Friend feed |
| GET | /races/discover | Yes | Search races |
| GET | /races/{id} | Yes | Race detail |
| POST | /races/{id}/register-interest | Yes | Mark interest |
| POST | /calendar/sync | Yes | Sync to Google Calendar |
| POST | /calendar/check-conflicts | Yes | Check availability |
| GET | /strava/auth-url | Yes | Strava OAuth URL |
| GET | /strava/callback | No | OAuth callback |
| POST | /strava/sync | Yes | Manual sync |
| DELETE | /strava/disconnect | Yes | Disconnect |
| POST | /voice/session | Yes | Create Daily room, start pipeline |
| POST | /voice/biometrics | Yes | Push real-time data |
| POST | /voice/end | Yes | End session |
| GET | /voice/sessions | Yes | Past transcripts |

---

## Environment Variables

```env
MONGODB_URI=mongodb+srv://...
MONGODB_DB_NAME=pacepilot_db
GCP_PROJECT_ID=...
GCP_REGION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
DAILY_API_KEY=...
STRAVA_CLIENT_ID=...
STRAVA_CLIENT_SECRET=...
STRAVA_REDIRECT_URI=...
GOOGLE_CALENDAR_CLIENT_ID=...
GOOGLE_CALENDAR_CLIENT_SECRET=...
JWT_SECRET=...
JWT_ALGORITHM=HS256
APP_ENV=development
APPLE_APP_BUNDLE_ID=com.fabianferno.PacePilot
```

---

## Tech Stack

| Layer | Library |
|-------|---------|
| Web framework | FastAPI 0.110+ |
| ASGI server | uvicorn |
| Voice pipeline | pipecat-ai[google,daily] |
| Gemini | google-genai, google-auth |
| Database | motor 3.4+ (async MongoDB) |
| Auth | python-jose[cryptography], passlib[bcrypt] |
| HTTP client | httpx |
| Scheduling | apscheduler |
| Config | pydantic-settings |
