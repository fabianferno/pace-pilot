# PacePilot — Product Requirements Document (PRD)

> **Document Version:** 1.0  
> **Date:** March 2026  
> **Status:** Ready for Development  
> **Audience:** Engineering team / Coding agents

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack & Infrastructure](#3-tech-stack--infrastructure)
4. [Data Models (MongoDB)](#4-data-models-mongodb)
5. [Backend Server (Python)](#5-backend-server-python)
6. [Gemini Live Voice Agent](#6-gemini-live-voice-agent)
7. [iOS App (Swift)](#7-ios-app-swift)
8. [Apple Watch Companion App](#8-apple-watch-companion-app)
9. [Feature Specifications](#9-feature-specifications)
10. [API Contracts](#10-api-contracts)
11. [Third-Party Integrations](#11-third-party-integrations)
12. [Development Phases](#12-development-phases)

---

## 1. Product Overview

### 1.1 What is PacePilot

PacePilot is a **voice-first AI running coach** powered by Google Gemini Live. The core product is a real-time conversational voice agent that rides alongside runners on every session — monitoring biometrics, adapting pacing in real time, answering questions mid-run, delivering motivation, and building a persistent coaching relationship across training cycles.

### 1.2 Core Differentiator

Unlike Runna and other plan-delivery apps, PacePilot's voice agent IS the product. Every touchpoint — onboarding, daily training, mid-run coaching, post-run analysis, race prep, community — is mediated through a live conversational AI with full access to the runner's real-time biometrics, training history, goals, and social context.

### 1.3 Key Product Pillars

| Pillar | Description |
|--------|-------------|
| **Live Voice Agent** | Gemini Live-powered conversational coach present on every run |
| **Real-Time Biometric Coaching** | HR, pace, cadence driving in-the-moment decisions |
| **Conversational Onboarding** | Voice-guided commitment funnel replacing static quiz UIs |
| **Auto-Tiered Communities** | Pace-based peer matching with leaderboards and agent-narrated social |
| **Proactive Life Integration** | Calendar sync, race discovery, voice-driven schedule management |

---

## 2. System Architecture

### 2.1 High-Level Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                │
│                                                                      │
│  ┌─────────────────┐          ┌──────────────────┐                   │
│  │   iOS App        │◄────────►│  Apple Watch App  │                  │
│  │   (Swift/UIKit)  │  Watch   │  (SwiftUI/       │                  │
│  │                  │Connectvty│   WatchKit)       │                  │
│  └────────┬─────────┘          └────────┬─────────┘                  │
│           │                             │                            │
│           │  WebRTC (audio stream)      │  Sensor data               │
│           │  REST API (data)            │  (HR, pace, GPS)           │
│           │  WebSocket (real-time)      │                            │
└───────────┼─────────────────────────────┼────────────────────────────┘
            │                             │
            ▼                             │
┌──────────────────────────────────────────────────────────────────────┐
│                        BACKEND LAYER                                 │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐        │
│  │              Python Server (FastAPI)                      │        │
│  │                                                          │        │
│  │  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐  │        │
│  │  │  REST API     │  │  WebRTC       │  │  WebSocket   │  │        │
│  │  │  Endpoints    │  │  Signaling    │  │  Handler     │  │        │
│  │  └──────┬───────┘  └───────┬───────┘  └──────┬───────┘  │        │
│  │         │                  │                  │          │        │
│  │         ▼                  ▼                  ▼          │        │
│  │  ┌──────────────────────────────────────────────────┐    │        │
│  │  │            Pipecat Pipeline                       │    │        │
│  │  │                                                  │    │        │
│  │  │  Audio In ──► Gemini Live ──► Audio Out           │    │        │
│  │  │               (S2S voice)                        │    │        │
│  │  │               + Function Calling                 │    │        │
│  │  │               + Tool Use                         │    │        │
│  │  └──────────────────────┬───────────────────────────┘    │        │
│  │                         │                                │        │
│  │         ┌───────────────┼───────────────┐                │        │
│  │         ▼               ▼               ▼                │        │
│  │  ┌────────────┐  ┌────────────┐  ┌──────────────┐       │        │
│  │  │ Plan Engine │  │ Analytics  │  │ Social/Comm  │       │        │
│  │  │ Service     │  │ Service    │  │ Service      │       │        │
│  │  └──────┬─────┘  └─────┬──────┘  └──────┬───────┘       │        │
│  │         └───────────────┼────────────────┘               │        │
│  └─────────────────────────┼────────────────────────────────┘        │
│                            ▼                                         │
│  ┌──────────────────────────────────────────────────────────┐        │
│  │                    MongoDB                                │        │
│  │  users │ plans │ workouts │ runs │ communities │ races    │        │
│  └──────────────────────────────────────────────────────────┘        │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
            │                             │
            ▼                             ▼
┌──────────────────────┐    ┌──────────────────────────┐
│  Google Cloud (GCP)   │    │  Third-Party APIs         │
│                       │    │                          │
│  Vertex AI Platform   │    │  Strava API              │
│  (Gemini Live API)    │    │  Apple HealthKit         │
│                       │    │  Google Calendar API     │
│  Service Account Auth │    │  Apple EventKit          │
│                       │    │  Race discovery APIs     │
└──────────────────────┘    └──────────────────────────┘
```

### 2.2 Communication Flow During a Live Run

```
Apple Watch                 iOS App                  Python Server              Gemini Live
(sensors)                  (client)                 (Pipecat)                  (Vertex AI)
    │                         │                         │                         │
    │──HR, pace, GPS, ───────►│                         │                         │
    │  cadence @ 1-5s         │                         │                         │
    │                         │──WebRTC audio stream───►│                         │
    │                         │──Sensor data payload───►│                         │
    │                         │                         │──Gemini WS session─────►│
    │                         │                         │  (audio + context)      │
    │                         │                         │                         │
    │                         │                         │◄──Voice response────────│
    │                         │                         │  (audio stream)         │
    │                         │◄──WebRTC audio out──────│                         │
    │                         │                         │                         │
    │                         │──Runner speaks──────────►──Forwarded to Gemini───►│
    │                         │                         │                         │
    │                         │                         │◄──Tool call (e.g.──────│
    │                         │                         │   get_heart_rate)       │
    │                         │                         │──Tool result───────────►│
    │                         │                         │                         │
    │                         │                         │◄──Voice with context───│
    │                         │◄──Audio response────────│                         │
    │◄──Haptic feedback───────│                         │                         │
    │                         │                         │                         │
```

---

## 3. Tech Stack & Infrastructure

### 3.1 Stack Summary

| Layer | Technology | Notes |
|-------|-----------|-------|
| **iOS App** | Swift, UIKit/SwiftUI, Combine | Minimum iOS 17. Universal app. |
| **Watch App** | SwiftUI, WatchKit, WatchConnectivity | watchOS 10+. Standalone + companion modes. |
| **Backend Server** | Python 3.12+, FastAPI, Pipecat | Handles REST, WebRTC signaling, Gemini sessions |
| **Voice Agent** | Pipecat + Google Gemini Live (S2S) | Server-to-server WebSocket to Vertex AI |
| **Database** | MongoDB | User data, plans, runs, communities |
| **Auth to GCP** | Google Service Account | JSON key file, Vertex AI platform |
| **Real-Time Transport** | WebRTC via Pipecat/Daily | Audio streaming between iOS app and server |
| **Wearable Data** | Apple HealthKit, WatchConnectivity | HR, pace, GPS, cadence, sleep, HRV |
| **External APIs** | Strava API, Google Calendar API, Apple EventKit | Training history, calendar sync |

### 3.2 GCP / Vertex AI Configuration

```
Project Setup:
├── GCP Project with Vertex AI API enabled
├── Service Account (roles/aiplatform.user)
│   └── JSON key file stored as environment variable
├── Gemini Live API access via Vertex AI endpoint
│   └── Region: us-central1 (or closest low-latency region)
└── Model: gemini-2.5-flash-native-audio-preview-12-2025
```

**Authentication flow:**
1. Python server loads service account JSON key from env
2. Uses `google-auth` library to generate access tokens
3. Passes token to Pipecat's Gemini Live service for WebSocket auth
4. Tokens auto-refresh on expiry (typically 1hr)

### 3.3 Pipecat Configuration

Pipecat is the orchestration framework for the voice pipeline. It manages:
- WebRTC transport (client ↔ server audio streaming)
- Gemini Live WebSocket connection (server ↔ Vertex AI)
- Function calling / tool use bridge
- Voice Activity Detection (VAD)
- Audio encoding/decoding (16-bit PCM, 16kHz in / 24kHz out)

**Key Pipecat service:**
```python
from pipecat.services.google.gemini_live.llm import GeminiLiveLLMService

# Initialize with Vertex AI service account
llm_service = GeminiLiveLLMService(
    api_key=vertex_ai_access_token,      # from service account
    model="models/gemini-2.5-flash-native-audio-preview-12-2025",
    voice_id="Charon",                    # or preferred voice
    system_instruction=PACEPILOT_SYSTEM_PROMPT,
    tools=PACEPILOT_TOOLS,               # function declarations
)
```

---

## 4. Data Models (MongoDB)

### 4.1 Collections Overview

```
pacepilot_db
├── users
├── training_plans
├── workouts
├── run_sessions
├── communities
├── leaderboards
├── races
└── agent_sessions
```

### 4.2 Collection Schemas

#### `users`
```json
{
  "_id": "ObjectId",
  "created_at": "datetime",
  "updated_at": "datetime",

  // Profile
  "email": "string",
  "display_name": "string",
  "avatar_url": "string | null",

  // Onboarding data (captured via voice agent)
  "onboarding_complete": "boolean",
  "goal": {
    "type": "enum: race | fitness | weight_loss | return_from_injury",
    "race_distance": "enum: 5k | 10k | half_marathon | marathon | ultra | null",
    "race_name": "string | null",
    "race_date": "date | null"
  },
  "experience_tier": "enum: beginner | intermediate | advanced | elite",
  "schedule": {
    "runs_per_week": "int (2-6)",
    "preferred_days": ["string"],       // e.g. ["mon", "wed", "fri", "sun"]
    "long_run_day": "string"            // e.g. "sun"
  },
  "pace_benchmark": {
    "distance": "enum: 5k | 10k",
    "time_seconds": "int",              // e.g. 1500 = 25:00 for 5K
    "recorded_at": "datetime"
  },
  "health_context": {
    "injuries": ["string"],
    "conditions": ["string"],
    "notes": "string"
  },

  // Connected services
  "strava": {
    "connected": "boolean",
    "athlete_id": "string | null",
    "access_token": "string | null",
    "refresh_token": "string | null",
    "token_expires_at": "datetime | null"
  },
  "apple_health": {
    "connected": "boolean"
  },
  "calendar": {
    "provider": "enum: google | apple | none",
    "google_calendar_id": "string | null",
    "sync_enabled": "boolean"
  },

  // Community
  "community_tier": "enum: discovery | foundation | momentum | velocity | elite",
  "community_id": "ObjectId | null",

  // Plan reference
  "active_plan_id": "ObjectId | null",

  // Preferences
  "voice_preference": "string",         // Gemini voice ID
  "coaching_style": "enum: motivational | analytical | balanced",
  "silent_mode_default": "boolean",
  "units": "enum: metric | imperial"
}
```

#### `training_plans`
```json
{
  "_id": "ObjectId",
  "user_id": "ObjectId",
  "created_at": "datetime",
  "updated_at": "datetime",

  "status": "enum: active | completed | abandoned | paused",
  "goal": {
    "type": "string",
    "race_distance": "string | null",
    "race_name": "string | null",
    "race_date": "date | null"
  },

  "duration_weeks": "int",
  "start_date": "date",
  "end_date": "date",
  "current_week": "int",
  "current_phase": "enum: base | build | peak | taper | recovery",

  "pace_zones": {
    "easy": { "min_per_km": "float", "max_per_km": "float" },
    "tempo": { "min_per_km": "float", "max_per_km": "float" },
    "interval": { "min_per_km": "float", "max_per_km": "float" },
    "race": { "min_per_km": "float", "max_per_km": "float" },
    "long_run": { "min_per_km": "float", "max_per_km": "float" }
  },

  "hr_zones": {
    "zone1": { "min_bpm": "int", "max_bpm": "int" },
    "zone2": { "min_bpm": "int", "max_bpm": "int" },
    "zone3": { "min_bpm": "int", "max_bpm": "int" },
    "zone4": { "min_bpm": "int", "max_bpm": "int" },
    "zone5": { "min_bpm": "int", "max_bpm": "int" }
  },

  "weeks": [
    {
      "week_number": "int",
      "phase": "string",
      "total_distance_km": "float",
      "workouts": ["ObjectId"]           // refs to workouts collection
    }
  ]
}
```

#### `workouts`
```json
{
  "_id": "ObjectId",
  "plan_id": "ObjectId",
  "user_id": "ObjectId",

  "week_number": "int",
  "day_of_week": "string",
  "scheduled_date": "date",
  "calendar_event_id": "string | null",  // Google Calendar / EventKit ID

  "type": "enum: easy_run | tempo | intervals | long_run | recovery | race_pace | strength | rest | cross_training",
  "status": "enum: scheduled | completed | skipped | rescheduled",

  "target": {
    "distance_km": "float | null",
    "duration_minutes": "int | null",
    "pace_zone": "string | null",
    "hr_zone": "string | null",
    "description": "string",            // human-readable: "8km tempo at 5:15/km"
    "segments": [
      {
        "type": "enum: warmup | main | cooldown | interval_work | interval_rest",
        "distance_km": "float | null",
        "duration_minutes": "float | null",
        "pace_zone": "string | null",
        "repetitions": "int | null"
      }
    ]
  },

  "completed_run_id": "ObjectId | null"  // ref to run_sessions
}
```

#### `run_sessions`
```json
{
  "_id": "ObjectId",
  "user_id": "ObjectId",
  "workout_id": "ObjectId | null",       // null for free runs

  "started_at": "datetime",
  "ended_at": "datetime",
  "duration_seconds": "int",

  "distance_km": "float",
  "avg_pace_per_km": "float",
  "avg_hr": "int",
  "max_hr": "int",
  "calories": "int | null",
  "elevation_gain_m": "float | null",

  "splits": [
    {
      "km": "int",
      "pace_seconds": "float",
      "avg_hr": "int",
      "elevation_m": "float | null"
    }
  ],

  "gps_track": [
    { "lat": "float", "lng": "float", "timestamp": "datetime", "altitude": "float | null" }
  ],

  "biometric_stream": [
    {
      "timestamp": "datetime",
      "hr": "int",
      "pace_per_km": "float",
      "cadence": "int | null",
      "distance_km": "float"
    }
  ],

  "agent_interactions": [
    {
      "timestamp": "datetime",
      "speaker": "enum: agent | runner",
      "transcript": "string",
      "trigger": "string | null"         // e.g. "hr_zone4_exceeded", "user_question", "interval_start"
    }
  ],

  "post_run_summary": "string",          // agent-generated debrief text
  "strava_activity_id": "string | null",
  "source": "enum: phone | watch"
}
```

#### `communities`
```json
{
  "_id": "ObjectId",
  "tier": "enum: discovery | foundation | momentum | velocity | elite",
  "name": "string",                      // e.g. "Velocity — Chennai"
  "location": {
    "city": "string | null",
    "country": "string | null",
    "coordinates": { "lat": "float", "lng": "float" } 
  },
  "member_ids": ["ObjectId"],
  "member_count": "int",
  "created_at": "datetime",

  "challenges": [
    {
      "id": "string",
      "title": "string",
      "type": "enum: distance | streak | speed",
      "target": "float",
      "start_date": "date",
      "end_date": "date",
      "leaderboard": [
        { "user_id": "ObjectId", "value": "float", "rank": "int" }
      ]
    }
  ]
}
```

#### `races`
```json
{
  "_id": "ObjectId",
  "name": "string",
  "date": "date",
  "location": {
    "city": "string",
    "country": "string",
    "coordinates": { "lat": "float", "lng": "float" }
  },
  "distance": "enum: 5k | 10k | half_marathon | marathon | ultra | other",
  "distance_km": "float",
  "registration_url": "string | null",
  "elevation_profile": "string | null",
  "description": "string | null",
  "source": "string"
}
```

#### `agent_sessions`
```json
{
  "_id": "ObjectId",
  "user_id": "ObjectId",
  "type": "enum: onboarding | pre_run | active_run | post_run | general",
  "started_at": "datetime",
  "ended_at": "datetime | null",
  "gemini_session_id": "string",
  "transcript": [
    {
      "timestamp": "datetime",
      "speaker": "enum: agent | user",
      "text": "string"
    }
  ],
  "tools_called": [
    {
      "timestamp": "datetime",
      "tool_name": "string",
      "input": "object",
      "output": "object"
    }
  ]
}
```

---

## 5. Backend Server (Python)

### 5.1 Project Structure

```
pacepilot-server/
├── main.py                          # FastAPI app entry point
├── requirements.txt
├── .env
│
├── config/
│   ├── settings.py                  # Env vars, GCP config, MongoDB URI
│   └── auth.py                      # Service account loader, token refresh
│
├── api/
│   ├── __init__.py
│   ├── routes/
│   │   ├── auth.py                  # User auth (Apple Sign-In, email)
│   │   ├── users.py                 # Profile CRUD, onboarding status
│   │   ├── plans.py                 # Plan generation, retrieval, updates
│   │   ├── workouts.py              # Workout CRUD, rescheduling
│   │   ├── runs.py                  # Run session recording, history
│   │   ├── communities.py           # Tier lookup, leaderboards, challenges
│   │   ├── races.py                 # Race discovery, registration links
│   │   ├── calendar.py              # Calendar sync operations
│   │   ├── strava.py                # OAuth flow, data sync
│   │   └── voice.py                 # WebRTC session init, voice endpoints
│   └── middleware/
│       ├── auth_middleware.py        # JWT verification
│       └── rate_limit.py
│
├── services/
│   ├── __init__.py
│   ├── plan_engine.py               # Training plan generation logic
│   ├── workout_generator.py         # Individual workout creation
│   ├── pace_calculator.py           # Pace zone derivation from benchmarks
│   ├── hr_zone_calculator.py        # HR zone estimation
│   ├── community_service.py         # Tier assignment, promotion logic
│   ├── race_service.py              # Race search and recommendation
│   ├── strava_service.py            # Strava API wrapper
│   ├── calendar_service.py          # Google Calendar / EventKit sync
│   ├── analytics_service.py         # Run analysis, PR detection, trends
│   └── notification_service.py      # Push notifications
│
├── voice/
│   ├── __init__.py
│   ├── pipeline.py                  # Pipecat pipeline definition
│   ├── session_manager.py           # Gemini Live session lifecycle
│   ├── system_prompts/
│   │   ├── onboarding.py            # Onboarding conversation prompt
│   │   ├── pre_run.py               # Pre-run briefing prompt
│   │   ├── active_run.py            # Mid-run coaching prompt
│   │   ├── post_run.py              # Post-run debrief prompt
│   │   └── general.py               # General Q&A prompt
│   ├── tools/
│   │   ├── __init__.py
│   │   ├── definitions.py           # Tool/function declarations for Gemini
│   │   ├── biometric_tools.py       # get_heart_rate, get_pace, get_distance, etc.
│   │   ├── plan_tools.py            # get_todays_workout, get_plan_status, etc.
│   │   ├── history_tools.py         # get_recent_runs, get_pr, get_weekly_mileage
│   │   ├── social_tools.py          # get_friend_activity, get_leaderboard_position
│   │   ├── calendar_tools.py        # schedule_run, reschedule_run, check_conflicts
│   │   ├── race_tools.py            # find_local_races, get_race_details
│   │   └── user_tools.py            # get_user_profile, update_preferences
│   └── context/
│       ├── run_context.py           # Real-time run state (rolling window)
│       └── user_context.py          # User profile + history loader
│
├── db/
│   ├── __init__.py
│   ├── connection.py                # MongoDB connection (motor async driver)
│   ├── models.py                    # Pydantic models matching schemas above
│   └── repositories/
│       ├── user_repo.py
│       ├── plan_repo.py
│       ├── workout_repo.py
│       ├── run_repo.py
│       ├── community_repo.py
│       └── race_repo.py
│
└── utils/
    ├── gcp_auth.py                  # Service account token management
    ├── strava_oauth.py              # Strava OAuth2 helpers
    └── formatters.py                # Pace/time formatting utilities
```

### 5.2 Core Dependencies

```txt
# requirements.txt
fastapi>=0.110.0
uvicorn[standard]>=0.29.0
pipecat-ai[google,daily]>=0.0.90
google-genai>=1.0.0
google-auth>=2.29.0
motor>=3.4.0                         # async MongoDB driver
pymongo>=4.7.0
pydantic>=2.7.0
python-dotenv>=1.0.0
httpx>=0.27.0                        # async HTTP client (Strava, Calendar)
python-jose[cryptography]>=3.3.0     # JWT handling
passlib[bcrypt]>=1.7.4
apscheduler>=3.10.0                  # Scheduled tasks (token refresh, sync)
```

### 5.3 Environment Variables

```env
# .env
MONGODB_URI=mongodb+srv://<user>:<pass>@<cluster>/pacepilot_db
MONGODB_DB_NAME=pacepilot_db

# GCP / Vertex AI
GCP_PROJECT_ID=your-gcp-project-id
GCP_REGION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# Pipecat / Daily (WebRTC)
DAILY_API_KEY=your-daily-api-key

# Strava
STRAVA_CLIENT_ID=your-strava-client-id
STRAVA_CLIENT_SECRET=your-strava-client-secret
STRAVA_REDIRECT_URI=https://api.pacepilot.app/strava/callback

# Google Calendar
GOOGLE_CALENDAR_CLIENT_ID=your-google-calendar-client-id
GOOGLE_CALENDAR_CLIENT_SECRET=your-google-calendar-client-secret

# App
JWT_SECRET=your-jwt-secret
APP_ENV=development
```

### 5.4 Server Entry Point

```python
# main.py
from fastapi import FastAPI
from contextlib import asynccontextmanager
from db.connection import connect_db, close_db
from api.routes import auth, users, plans, workouts, runs, communities, races, calendar, strava, voice

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()

app = FastAPI(title="PacePilot API", version="1.0.0", lifespan=lifespan)

# Routes
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(plans.router, prefix="/api/plans", tags=["plans"])
app.include_router(workouts.router, prefix="/api/workouts", tags=["workouts"])
app.include_router(runs.router, prefix="/api/runs", tags=["runs"])
app.include_router(communities.router, prefix="/api/communities", tags=["communities"])
app.include_router(races.router, prefix="/api/races", tags=["races"])
app.include_router(calendar.router, prefix="/api/calendar", tags=["calendar"])
app.include_router(strava.router, prefix="/api/strava", tags=["strava"])
app.include_router(voice.router, prefix="/api/voice", tags=["voice"])
```

---

## 6. Gemini Live Voice Agent

### 6.1 Architecture: Server-to-Server via Pipecat

The voice agent uses the **server-to-server** implementation approach as specified in the [Gemini Live API docs](https://ai.google.dev/gemini-api/docs/live):

1. **iOS app** captures mic audio and streams it to the Python server via WebRTC (using Pipecat's Daily transport)
2. **Python server** runs a Pipecat pipeline that forwards the audio to Gemini Live via WebSocket
3. **Gemini Live** processes audio, generates speech responses, and triggers tool calls
4. **Python server** handles tool calls (fetch HR data, check plan, query MongoDB) and returns results to Gemini
5. **Gemini Live** incorporates tool results into its spoken response
6. **Python server** streams the response audio back to the iOS app via WebRTC

### 6.2 Pipecat Pipeline Definition

```python
# voice/pipeline.py
import asyncio
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.runner import PipelineRunner
from pipecat.pipeline.task import PipelineTask, PipelineParams
from pipecat.transports.services.daily import DailyTransport, DailyParams
from pipecat.services.google.gemini_live.llm import GeminiLiveLLMService
from pipecat.processors.frameworks.rtvi import RTVIProcessor
from voice.tools.definitions import PACEPILOT_TOOLS
from voice.context.run_context import RunContextProcessor
from config.auth import get_vertex_ai_token

async def create_voice_session(
    user_id: str,
    session_type: str,       # "onboarding" | "active_run" | "general"
    system_prompt: str,
    daily_room_url: str,
    daily_token: str,
):
    """Create and run a Pipecat pipeline for a voice session."""

    transport = DailyTransport(
        daily_room_url,
        daily_token,
        "PacePilot",
        DailyParams(
            audio_in_enabled=True,
            audio_out_enabled=True,
            vad_enabled=True,
            vad_analyzer=None,        # Use Gemini's built-in VAD
        ),
    )

    token = await get_vertex_ai_token()

    llm = GeminiLiveLLMService(
        api_key=token,
        model="models/gemini-2.5-flash-native-audio-preview-12-2025",
        voice_id="Charon",
        system_instruction=system_prompt,
        tools=PACEPILOT_TOOLS,
    )

    # Context processor injects real-time sensor data
    run_context = RunContextProcessor(user_id=user_id)

    pipeline = Pipeline([
        transport.input(),
        run_context,                  # Injects biometric context
        llm,
        transport.output(),
    ])

    task = PipelineTask(
        pipeline,
        params=PipelineParams(allow_interruptions=True),
    )

    runner = PipelineRunner()
    await runner.run(task)
```

### 6.3 Tool Declarations for Gemini

These are the function declarations passed to Gemini Live. When the agent decides it needs data, it calls these tools, and Pipecat routes the call to your Python handler.

```python
# voice/tools/definitions.py

PACEPILOT_TOOLS = [
    {
        "name": "get_current_biometrics",
        "description": "Get the runner's current real-time biometrics during an active run.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "get_todays_workout",
        "description": "Get the scheduled workout for today including pace targets, distance, and segments.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "get_run_progress",
        "description": "Get current run progress: distance covered, elapsed time, current split, splits history.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "get_recent_runs",
        "description": "Get the runner's recent run history for comparison and motivation.",
        "parameters": {
            "type": "object",
            "properties": {
                "count": {
                    "type": "integer",
                    "description": "Number of recent runs to retrieve (default 5)"
                }
            },
            "required": []
        }
    },
    {
        "name": "get_personal_records",
        "description": "Get the runner's personal records across all distances.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "get_weekly_stats",
        "description": "Get weekly mileage, run count, and training load for the current and past weeks.",
        "parameters": {
            "type": "object",
            "properties": {
                "weeks": {
                    "type": "integer",
                    "description": "Number of weeks to look back (default 4)"
                }
            },
            "required": []
        }
    },
    {
        "name": "get_plan_status",
        "description": "Get the overall training plan status: current week, phase, completion rate, upcoming workouts.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "get_friend_activity",
        "description": "Get recent run activity from the runner's friends and community.",
        "parameters": {
            "type": "object",
            "properties": {
                "count": {
                    "type": "integer",
                    "description": "Number of friend activities to retrieve (default 3)"
                }
            },
            "required": []
        }
    },
    {
        "name": "get_leaderboard_position",
        "description": "Get the runner's current position on their community tier leaderboard.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "find_local_races",
        "description": "Search for upcoming races near the runner's location.",
        "parameters": {
            "type": "object",
            "properties": {
                "distance_filter": {
                    "type": "string",
                    "description": "Filter by race distance: 5k, 10k, half_marathon, marathon, ultra, or all",
                    "enum": ["5k", "10k", "half_marathon", "marathon", "ultra", "all"]
                },
                "radius_km": {
                    "type": "integer",
                    "description": "Search radius in kilometers (default 50)"
                }
            },
            "required": []
        }
    },
    {
        "name": "schedule_run_to_calendar",
        "description": "Schedule a run workout to the user's connected calendar.",
        "parameters": {
            "type": "object",
            "properties": {
                "workout_id": { "type": "string", "description": "The workout ID to schedule" },
                "date": { "type": "string", "description": "ISO date string for the scheduled run" },
                "time": { "type": "string", "description": "Time in HH:MM format (24hr)" }
            },
            "required": ["workout_id", "date", "time"]
        }
    },
    {
        "name": "reschedule_workout",
        "description": "Move a workout to a different day. The system will rebalance the week.",
        "parameters": {
            "type": "object",
            "properties": {
                "workout_id": { "type": "string", "description": "The workout ID to reschedule" },
                "new_date": { "type": "string", "description": "New ISO date string" },
                "reason": { "type": "string", "description": "Reason for rescheduling (logged)" }
            },
            "required": ["workout_id", "new_date"]
        }
    },
    {
        "name": "update_user_profile",
        "description": "Update user profile fields during onboarding or preference changes.",
        "parameters": {
            "type": "object",
            "properties": {
                "field": { "type": "string", "description": "Field path to update, e.g. 'goal.race_distance'" },
                "value": { "type": "string", "description": "New value" }
            },
            "required": ["field", "value"]
        }
    },
    {
        "name": "generate_training_plan",
        "description": "Generate a new training plan based on the user's profile and goals. Call after onboarding is complete.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "mark_not_feeling_well",
        "description": "User reports not feeling 100%. Adapt today's workout to be lighter or suggest rest.",
        "parameters": {
            "type": "object",
            "properties": {
                "reason": {
                    "type": "string",
                    "description": "Why the user isn't feeling well: illness, fatigue, injury, stress, sleep, other"
                }
            },
            "required": ["reason"]
        }
    }
]
```

### 6.4 System Prompts

#### Onboarding Prompt
```python
# voice/system_prompts/onboarding.py

ONBOARDING_SYSTEM_PROMPT = """
You are PacePilot, a world-class AI running coach. You are conducting an onboarding
conversation with a new runner. Your job is to get to know them, understand their
goals, and build their personalized training plan.

## Your Personality
- Warm, confident, knowledgeable
- You sound like a real coach who genuinely cares, not a robot
- Use the runner's name once you know it
- Be conversational — ask follow-up questions, react to their answers
- Show excitement about their goals

## Onboarding Flow
Guide the conversation through these steps naturally (don't rush, don't sound scripted):

1. **Introduction** — Introduce yourself as PacePilot, their personal running coach. 
   Ask their name. Set the tone: "I'm going to be with you on every run."

2. **Goal Discovery** — Ask what brought them to PacePilot. Are they training for a 
   race? Getting fit? Coming back from injury? If a race, ask which one and when.
   Use update_user_profile tool to save each answer.

3. **Experience Assessment** — Ask about their running background naturally:
   "How long have you been running?" "What's the longest you've run recently?"
   "How often do you currently run?" Map to: beginner, intermediate, advanced, elite.

4. **Schedule** — Ask how many days they can realistically commit to running (2-6).
   Which days work best? When do they prefer their long run?

5. **Pace Calibration** — Ask if they have a recent 5K or 10K time. If yes, record it.
   If no, explain you'll do a calibration run together in week 1. Make this feel 
   exciting, not like a test.

6. **Health Check** — Ask if there's anything about their body you should know:
   current injuries, health conditions, recent surgery, etc. Be sensitive.

7. **Device Connections** — Mention connecting Strava (for history), Apple Health 
   (for biometrics), and their calendar (for scheduling). Explain why each matters.

8. **Plan Generation** — Once you have everything, call generate_training_plan.
   Walk them through week 1. Explain the logic. Ask if it feels right.
   Make the commitment moment powerful: "Your plan is locked in. I'll be with you
   every step. Let's do this."

## Rules
- Save data as you go using update_user_profile — don't wait until the end
- If the user seems uncertain, reassure them. Adapt your language to their level.
- Keep the conversation under 5 minutes total
- At the end, confirm: name, goal, experience, schedule, pace, health flags
"""
```

#### Active Run Prompt
```python
# voice/system_prompts/active_run.py

ACTIVE_RUN_SYSTEM_PROMPT = """
You are PacePilot, a live AI running coach. You are currently coaching {user_name}
during an active run. You have real-time access to their biometrics and training data
through your tools.

## Today's Workout
{workout_description}

## Runner Profile
- Experience: {experience_tier}
- Goal: {goal_description}
- Plan week: {current_week} of {total_weeks} ({current_phase} phase)
- Coaching style preference: {coaching_style}

## Your Behavior Modes

### Active Coaching Mode (intervals, tempo, race pace, final push)
- Speak every 30-60 seconds
- Call pace, HR zone, interval countdowns
- Be sharp and directive: "Push. 200 meters. Hold this."
- Call get_current_biometrics frequently to stay accurate

### Companion Mode (easy runs, recovery, warm-up, cool-down)
- Check in every 3-5 minutes
- Be conversational: share tips, trivia, pro runner facts
- Open to questions — if the runner talks, engage fully
- Mention friend activity occasionally using get_friend_activity

### Silent Mode (user requests quiet, or during deep focus)
- Only speak for: dangerous HR readings, distance milestones, session transitions
- Resume normal mode when user speaks or session type changes

## Coaching Rules
1. ALWAYS use tools to get real data before making claims about pace, HR, distance
2. Never guess biometrics — call get_current_biometrics
3. Compare to history using get_recent_runs when motivating
4. If HR exceeds zone 4 for >2 minutes, suggest slowing down
5. If HR shows anomalous spike, issue safety alert
6. Call interval starts/stops precisely using workout segment data
7. For warm-up: guide gradually, don't rush
8. For cool-down: celebrate the session, preview tomorrow
9. Breathing reminders every 10-15 min or when cadence drops
10. Posture/form cues: "Relax your shoulders", "Light feet", "Eyes forward"

## Tone
- Never condescending. Never generic.
- Reference their specific data: "Your last tempo was 5:18, you're at 5:12 today"
- When they're struggling, be empathetic but firm
- When they're nailing it, be genuinely excited
- Silence is a coaching tool — don't fill every moment with talk

## Safety
- If HR exceeds 95% of estimated max for >3 min: strongly suggest stopping
- If user reports sharp pain: advise stopping immediately
- If user reports dizziness/chest pain: advise stopping and seeking help
- Never encourage running through sharp or unusual pain
"""
```

---

## 7. iOS App (Swift)

### 7.1 Project Structure

```
PacePilot/
├── PacePilot.xcodeproj
├── PacePilot/
│   ├── App/
│   │   ├── PacePilotApp.swift            # App entry point
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   │
│   ├── Core/
│   │   ├── Network/
│   │   │   ├── APIClient.swift           # Base HTTP client (URLSession)
│   │   │   ├── APIEndpoints.swift        # Endpoint definitions
│   │   │   ├── AuthManager.swift         # JWT token storage/refresh
│   │   │   └── WebRTCClient.swift        # Daily/Pipecat WebRTC wrapper
│   │   ├── Services/
│   │   │   ├── VoiceSessionService.swift # Manages voice agent lifecycle
│   │   │   ├── HealthKitService.swift    # HealthKit read/stream
│   │   │   ├── LocationService.swift     # CoreLocation for GPS tracking
│   │   │   ├── WorkoutService.swift      # HKWorkoutSession management
│   │   │   ├── CalendarService.swift     # EventKit integration
│   │   │   ├── StravaService.swift       # Strava OAuth + sync
│   │   │   ├── WatchConnector.swift      # WatchConnectivity bridge
│   │   │   └── NotificationService.swift # Push notification handling
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   ├── TrainingPlan.swift
│   │   │   ├── Workout.swift
│   │   │   ├── RunSession.swift
│   │   │   ├── Community.swift
│   │   │   ├── Race.swift
│   │   │   └── BiometricReading.swift
│   │   └── Utilities/
│   │       ├── PaceFormatter.swift
│   │       ├── TimeFormatter.swift
│   │       └── Constants.swift
│   │
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift      # Voice-guided onboarding UI
│   │   │   └── OnboardingViewModel.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift            # Dashboard: today's workout, stats
│   │   │   └── HomeViewModel.swift
│   │   ├── Plan/
│   │   │   ├── PlanView.swift            # Calendar view of training plan
│   │   │   ├── WorkoutDetailView.swift
│   │   │   └── PlanViewModel.swift
│   │   ├── ActiveRun/
│   │   │   ├── ActiveRunView.swift       # Live run screen with agent
│   │   │   ├── ActiveRunViewModel.swift  # Streams biometrics, manages voice
│   │   │   └── RunMetricsOverlay.swift   # Pace, HR, distance, time display
│   │   ├── PostRun/
│   │   │   ├── PostRunView.swift         # Run summary + agent debrief
│   │   │   └── PostRunViewModel.swift
│   │   ├── Community/
│   │   │   ├── CommunityView.swift       # Tier, leaderboard, challenges
│   │   │   └── CommunityViewModel.swift
│   │   ├── Races/
│   │   │   ├── RaceDiscoveryView.swift   # Local race browser
│   │   │   └── RaceDetailView.swift
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift
│   │   │   └── SettingsView.swift
│   │   └── History/
│   │       ├── RunHistoryView.swift
│   │       └── RunDetailView.swift
│   │
│   └── Resources/
│       ├── Assets.xcassets
│       ├── LaunchScreen.storyboard
│       └── Info.plist
│
├── PacePilotWatch/                       # watchOS target (see Section 8)
├── PacePilotWatchExtension/
└── Shared/                               # Shared models between iOS & watchOS
    ├── SharedModels.swift
    └── WatchMessages.swift               # WatchConnectivity message types
```

### 7.2 Key Implementation: Voice Session Lifecycle

```swift
// Core/Services/VoiceSessionService.swift

import Foundation
import Combine

enum VoiceSessionType: String, Codable {
    case onboarding
    case preRun = "pre_run"
    case activeRun = "active_run"
    case postRun = "post_run"
    case general
}

enum VoiceSessionState {
    case idle
    case connecting
    case active
    case reconnecting
    case ended
}

class VoiceSessionService: ObservableObject {
    @Published var state: VoiceSessionState = .idle
    @Published var isAgentSpeaking: Bool = false
    @Published var lastTranscript: String = ""
    
    private var webRTCClient: WebRTCClient?
    private var biometricTimer: Timer?
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    /// Start a voice session with the PacePilot agent
    func startSession(type: VoiceSessionType, metadata: [String: Any] = [:]) async throws {
        state = .connecting
        
        // 1. Request a Daily room + token from our backend
        let response: VoiceSessionResponse = try await apiClient.post(
            "/api/voice/session",
            body: [
                "type": type.rawValue,
                "metadata": metadata
            ]
        )
        
        // 2. Connect to Daily room via WebRTC
        webRTCClient = WebRTCClient()
        try await webRTCClient?.connect(
            roomURL: response.dailyRoomURL,
            token: response.dailyToken
        )
        
        // 3. Session is now active — audio flows through Pipecat to Gemini
        state = .active
        
        // 4. If this is an active run, start streaming biometrics
        if type == .activeRun {
            startBiometricStream()
        }
    }
    
    /// Send real-time biometric data to the server during a run
    private func startBiometricStream() {
        biometricTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                guard let self = self else { return }
                let biometrics = await HealthKitService.shared.getCurrentBiometrics()
                try? await self.apiClient.post(
                    "/api/voice/biometrics",
                    body: biometrics.toDictionary()
                )
            }
        }
    }
    
    /// End the voice session
    func endSession() async {
        biometricTimer?.invalidate()
        biometricTimer = nil
        await webRTCClient?.disconnect()
        webRTCClient = nil
        state = .ended
    }
}
```

### 7.3 Key Implementation: Active Run Screen

```swift
// Features/ActiveRun/ActiveRunViewModel.swift

import Foundation
import Combine
import HealthKit

class ActiveRunViewModel: ObservableObject {
    @Published var currentPace: Double = 0        // seconds per km
    @Published var currentHR: Int = 0
    @Published var distance: Double = 0           // km
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentCadence: Int = 0
    @Published var splits: [Split] = []
    @Published var agentState: AgentCoachingMode = .companion
    @Published var isRunning: Bool = false
    
    private let voiceService: VoiceSessionService
    private let healthKitService: HealthKitService
    private let locationService: LocationService
    private let workoutService: WorkoutService
    private var cancellables = Set<AnyCancellable>()
    
    struct Split {
        let km: Int
        let paceSeconds: Double
        let avgHR: Int
    }
    
    enum AgentCoachingMode {
        case active, companion, silent
    }
    
    init(voiceService: VoiceSessionService, 
         healthKitService: HealthKitService,
         locationService: LocationService,
         workoutService: WorkoutService) {
        self.voiceService = voiceService
        self.healthKitService = healthKitService
        self.locationService = locationService
        self.workoutService = workoutService
    }
    
    func startRun(workout: Workout?) async throws {
        // 1. Start HealthKit workout session
        try await workoutService.startWorkout(type: .running)
        
        // 2. Start location tracking
        locationService.startTracking()
        
        // 3. Start voice session with PacePilot agent
        try await voiceService.startSession(
            type: .activeRun,
            metadata: [
                "workout_id": workout?.id ?? "free_run",
                "workout_type": workout?.type.rawValue ?? "free"
            ]
        )
        
        // 4. Subscribe to real-time health data
        healthKitService.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentHR)
        
        locationService.pacePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentPace)
        
        locationService.distancePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$distance)
        
        isRunning = true
    }
    
    func stopRun() async throws {
        isRunning = false
        
        // 1. Stop workout session
        let workoutData = try await workoutService.stopWorkout()
        
        // 2. Stop location tracking
        let gpsTrack = locationService.stopTracking()
        
        // 3. Save run to backend
        try await saveRunSession(workoutData: workoutData, gpsTrack: gpsTrack)
        
        // 4. Transition voice to post-run debrief
        // (The backend handles switching the system prompt)
    }
    
    private func saveRunSession(workoutData: HKWorkout, gpsTrack: [CLLocation]) async throws {
        let session = RunSessionPayload(
            duration: workoutData.duration,
            distance: distance,
            avgPace: currentPace,
            avgHR: currentHR,
            splits: splits,
            gpsTrack: gpsTrack.map { GPSPoint(lat: $0.coordinate.latitude, lng: $0.coordinate.longitude, timestamp: $0.timestamp) }
        )
        try await APIClient.shared.post("/api/runs", body: session)
    }
}
```

---

## 8. Apple Watch Companion App

### 8.1 Watch App Structure

```
PacePilotWatch/
├── PacePilotWatchApp.swift               # Watch app entry
├── Views/
│   ├── WatchHomeView.swift               # Today's workout summary
│   ├── WatchActiveRunView.swift          # Live run metrics display
│   ├── WatchRunControlsView.swift        # Start/pause/stop buttons
│   └── WatchComplicationView.swift       # Watch face complication
├── Services/
│   ├── WatchWorkoutManager.swift         # HKWorkoutSession on watch
│   ├── WatchConnectivityManager.swift    # WatchConnectivity to phone
│   ├── WatchSensorManager.swift          # Direct sensor reads (HR, location)
│   └── WatchHapticManager.swift          # Haptic feedback patterns
└── Models/
    └── WatchRunState.swift               # Run state shared with phone
```

### 8.2 Key Capabilities

| Feature | Implementation | Notes |
|---------|---------------|-------|
| **One-tap launch** | Complication → `WatchActiveRunView` | Starts today's scheduled workout |
| **Live metrics** | `HKWorkoutSession` + `HKLiveWorkoutBuilder` | HR, pace, distance, calories in real-time |
| **Haptic cues** | `WKInterfaceDevice.play()` | Interval transitions, pace alerts, milestones |
| **Sensor streaming** | `WatchConnectivity.transferUserInfo()` | Sends HR + pace to phone every 3s |
| **Standalone mode** | Watch GPS + cellular | Voice via phone relay; metrics standalone |
| **Voice input** | Raise-to-speak → phone relay → server | User asks agent questions via watch mic |

### 8.3 Watch ↔ Phone Communication

```swift
// Shared/WatchMessages.swift

enum WatchMessageType: String, Codable {
    case biometricUpdate       // Watch → Phone: HR, pace, cadence, GPS
    case runCommand            // Watch → Phone: start, pause, stop, lap
    case voiceInput            // Watch → Phone: mic audio chunk
    case runStateUpdate        // Phone → Watch: agent status, workout segment
    case hapticTrigger         // Phone → Watch: trigger haptic pattern
    case workoutSync           // Phone → Watch: today's workout data
}

struct BiometricUpdate: Codable {
    let timestamp: Date
    let heartRate: Int
    let pacePerKm: Double
    let cadence: Int?
    let distanceKm: Double
    let latitude: Double
    let longitude: Double
    let altitude: Double?
}
```

---

## 9. Feature Specifications

### 9.1 Onboarding (Voice-Guided)

**Trigger:** First app launch after account creation.

**Flow:**
1. App shows minimal UI: PacePilot logo, waveform animation, "Tap to start"
2. User taps → voice session starts (type: `onboarding`)
3. Agent conducts intake conversation (see system prompt §6.4)
4. As agent gathers info, it calls `update_user_profile` tool for each data point
5. After all data captured, agent calls `generate_training_plan`
6. Agent walks user through week 1, gets confirmation
7. Session ends → app navigates to Home with plan visible

**UI during onboarding:**
- Fullscreen waveform visualization showing agent speaking / listening
- Subtle text overlay showing what the agent just said (accessibility)
- Progress dots (optional) showing rough onboarding stage
- No form fields, no buttons beyond start/stop

### 9.2 Active Run with Voice Coach

**Trigger:** User taps "Start Run" from Home or Watch.

**Pre-Run:**
1. App starts `HKWorkoutSession` + `CoreLocation`
2. Starts voice session (type: `active_run`) with today's workout context
3. Agent delivers 30-second briefing

**During Run:**
1. Biometrics stream to server every 5s
2. Agent monitors and speaks based on coaching mode rules
3. Runner can speak at any time — agent interrupts its own output to listen
4. Agent calls tools as needed (biometrics, plan, history, social)
5. Haptic feedback on watch for key moments

**Post-Run:**
1. User taps "Stop" → workout session ends
2. Agent automatically delivers verbal debrief
3. Run data saved to MongoDB
4. Activity synced to Strava if connected
5. App shows PostRunView with splits, map, summary

### 9.3 Training Plan Engine

**Plan generation logic (in `services/plan_engine.py`):**

1. Determine plan duration from race date (or default 12 weeks for fitness)
2. Calculate pace zones from 5K/10K benchmark using Daniels' VDOT tables
3. Estimate HR zones using Karvonen formula (max HR = 220 - age, or from HealthKit)
4. Structure phases: Base (30%) → Build (35%) → Peak (15%) → Taper (15%) → Race + Recovery
5. Distribute workouts across preferred days respecting: hard-easy principle, long run placement, rest day spacing
6. Generate individual workout targets for each session
7. Write plan + workouts to MongoDB
8. Push initial week to user's calendar

### 9.4 Calendar Sync

**Provider support:**
- **Google Calendar:** OAuth2 via Google Calendar API. Server-side CRUD.
- **Apple Calendar:** Via EventKit on-device. App creates/updates events locally.

**Behavior:**
- On plan generation: all workouts for the next 2 weeks are pushed to calendar
- Rolling window: as workouts are completed, next week's workouts are added
- On reschedule (via voice or UI): calendar events updated automatically
- Conflict detection: before scheduling, check for existing events in the time slot. If conflict, agent suggests alternatives.

### 9.5 PacePilot Communities

**Tier assignment:**
- Calculated from user's average easy-run pace over last 4 weeks
- Tiers: Discovery (7:30+ min/km), Foundation (6:00–7:30), Momentum (5:00–6:00), Velocity (4:00–5:00), Elite (sub-4:00)
- Re-evaluated weekly after each run sync
- Auto-promotion triggers voice celebration from agent

**Leaderboards (per community):**
- Weekly distance
- Consistency streak (consecutive weeks hitting plan)
- PR improvements (percentage improvement in any distance)
- Community challenges (admin-set goals)

**Community matching:**
- Global tier + optional location-based grouping
- If enough users in a city at the same tier → create city-specific community

### 9.6 Race Discovery

**Data sources:**
- Scraped/aggregated race databases (seed initially, then build)
- User-submitted races
- Strava local events (if available via API)

**Agent integration:**
- Agent proactively suggests races aligned with training timeline
- For registered races, agent fetches course data and adjusts plan (elevation prep, taper timing)
- Agent can walk user through registration links

---

## 10. API Contracts

### 10.1 REST Endpoints

#### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Create account (email or Apple Sign-In) |
| `POST` | `/api/auth/login` | Login, returns JWT |
| `POST` | `/api/auth/refresh` | Refresh JWT |

#### Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/users/me` | Get current user profile |
| `PATCH` | `/api/users/me` | Update profile fields |
| `GET` | `/api/users/me/stats` | Get aggregated stats (total runs, distance, PRs) |

#### Plans
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/plans/generate` | Generate new training plan |
| `GET` | `/api/plans/active` | Get active plan with workouts |
| `PATCH` | `/api/plans/{id}` | Update plan (pause, adjust) |
| `GET` | `/api/plans/{id}/workouts` | Get all workouts for a plan |

#### Workouts
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/workouts/today` | Get today's scheduled workout |
| `GET` | `/api/workouts/week` | Get current week's workouts |
| `PATCH` | `/api/workouts/{id}/reschedule` | Reschedule a workout |
| `PATCH` | `/api/workouts/{id}/skip` | Mark workout as skipped |

#### Runs
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/runs` | Save a completed run session |
| `GET` | `/api/runs` | Get run history (paginated) |
| `GET` | `/api/runs/{id}` | Get run detail with splits + GPS |
| `GET` | `/api/runs/recent?count=5` | Get N most recent runs |

#### Communities
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/communities/me` | Get user's community + tier |
| `GET` | `/api/communities/{id}/leaderboard` | Get tier leaderboard |
| `GET` | `/api/communities/{id}/challenges` | Get active challenges |
| `GET` | `/api/communities/friends/activity` | Get friend activity feed |

#### Races
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/races/discover` | Search races (location, distance, date range) |
| `GET` | `/api/races/{id}` | Get race details |
| `POST` | `/api/races/{id}/register-interest` | Mark interest in race |

#### Calendar
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/calendar/sync` | Sync workouts to calendar |
| `POST` | `/api/calendar/check-conflicts` | Check time slot availability |
| `DELETE` | `/api/calendar/events/{id}` | Remove a synced event |

#### Voice
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/voice/session` | Create new voice session (returns Daily room + token) |
| `POST` | `/api/voice/biometrics` | Push real-time biometric data during active run |
| `POST` | `/api/voice/end` | End voice session, get transcript |
| `GET` | `/api/voice/sessions` | Get past voice session transcripts |

#### Strava
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/strava/auth-url` | Get Strava OAuth URL |
| `GET` | `/api/strava/callback` | Handle OAuth callback |
| `POST` | `/api/strava/sync` | Trigger manual sync of Strava data |
| `DELETE` | `/api/strava/disconnect` | Disconnect Strava |

---

## 11. Third-Party Integrations

### 11.1 Strava API

**Purpose:** Import training history, PRs, weekly mileage. Post-run activity upload.

**OAuth Flow:**
1. iOS app opens Strava auth URL (from `/api/strava/auth-url`)
2. User authorizes → redirect to server callback
3. Server exchanges code for access + refresh tokens, stores in user doc
4. Server syncs last 90 days of activities on first connection

**Ongoing sync:**
- After each run: POST activity to Strava via API
- Weekly background sync: pull latest activities to detect outdoor runs logged elsewhere

### 11.2 Apple HealthKit

**Purpose:** Real-time biometrics during runs, resting HR, HRV, sleep data.

**Permissions requested:**
- Heart rate (read, real-time)
- Workout routes (read/write)
- Resting heart rate (read)
- Heart rate variability (read)
- Sleep analysis (read)
- Active energy (read)

### 11.3 Google Calendar API

**Purpose:** Schedule and manage workout events on user's calendar.

**OAuth Flow:** Standard Google OAuth2 (server-side). Store refresh tokens in user doc.

**Operations:** Create events, update events, delete events, read free/busy.

### 11.4 Apple EventKit

**Purpose:** Alternative calendar sync for users who don't use Google Calendar.

**Implementation:** On-device via EventKit framework. iOS app directly creates/manages events.

---

## 12. Development Phases

### Phase 1 — Foundation (Weeks 1–4)
| Component | Deliverable |
|-----------|------------|
| **Backend** | FastAPI project scaffolding, MongoDB connection, user auth (JWT), basic CRUD for users/plans/workouts/runs |
| **Voice** | Pipecat pipeline with Gemini Live, basic echo test, system prompt loading, single tool (get user profile) |
| **iOS** | Project setup, auth flow (Apple Sign-In), navigation skeleton, API client, HealthKit permissions |
| **Watch** | Project setup, WatchConnectivity bridge, basic sensor reads |

### Phase 2 — Voice Agent Core (Weeks 5–8)
| Component | Deliverable |
|-----------|------------|
| **Backend** | Plan engine (VDOT-based pace zones, periodization, workout generation), all tool handlers implemented |
| **Voice** | Onboarding prompt + flow working end-to-end, active run prompt with biometric tools, tool calling for all 16 tools |
| **iOS** | Onboarding UI (waveform + voice), WebRTC integration with Pipecat, active run screen with live metrics, HealthKit streaming |
| **Watch** | Live workout session, biometric streaming to phone, haptic engine |

### Phase 3 — Full Features (Weeks 9–12)
| Component | Deliverable |
|-----------|------------|
| **Backend** | Community service (tier assignment, leaderboards), race discovery service, calendar sync (Google + EventKit), Strava integration |
| **Voice** | Post-run debrief, friend activity narration, race suggestions via voice, calendar management via voice |
| **iOS** | Plan calendar view, community/leaderboard screens, race discovery, run history with maps, profile/settings |
| **Watch** | Complication, standalone run support, raise-to-speak input |

### Phase 4 — Polish & Launch Prep (Weeks 13–16)
| Component | Deliverable |
|-----------|------------|
| **All** | End-to-end testing across all flows, performance optimization (voice latency <500ms), offline resilience, error handling |
| **Voice** | Prompt tuning from real test runs, voice personality refinement, edge case handling (bad signal, watch disconnect) |
| **iOS** | UI polish, animations, onboarding flow refinement, App Store assets |
| **Watch** | UI polish, battery optimization, standalone reliability testing |
| **Infra** | Production GCP setup, monitoring, logging, CI/CD pipeline |

---

> **End of PRD.** This document provides everything needed to begin development. Each section is designed to be independently actionable — backend, voice agent, iOS app, and watch app can be developed in parallel following the contracts and schemas defined above.
