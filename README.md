# PacePilot

A voice-first AI running coach powered by Google Gemini Live. PacePilot talks to you mid-run, monitors your heart rate and pace via Apple Watch, and adapts coaching in real time.

## Architecture

```
Apple Watch ──(BLE/WatchConnectivity @ 3s)──► iOS App ──(WebRTC)──► FastAPI + Pipecat ──(WebSocket)──► Gemini Live (Vertex AI)
   HR, pace, GPS                              Stream biometrics       Context injection        Voice coaching
                                              + audio                 + 16 tool calls          + function calling
```

The voice agent runs **server-side**: the iOS app streams audio via WebRTC (Daily transport) to a Python backend running Pipecat, which manages a bidirectional WebSocket to Gemini Live on Vertex AI. Real-time biometrics from the Apple Watch are injected into the pipeline context so Gemini's tool calls always return current sensor data.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| AI / Voice | Gemini Live (`gemini-2.5-flash-native-audio-preview`), Vertex AI, Pipecat |
| Backend | Python 3.12+, FastAPI, Motor (async MongoDB) |
| Real-Time Transport | WebRTC via Daily.co |
| Database | MongoDB |
| iOS App | Swift, UIKit, SwiftUI, HealthKit, CoreLocation |
| Watch App | SwiftUI, WatchKit, WatchConnectivity, HealthKit |
| Landing Page | Next.js, TypeScript, Tailwind CSS |

## Prerequisites

- **Python 3.12+**
- **Node.js 18+** and **pnpm**
- **MongoDB** instance (local or Atlas)
- **GCP project** with Vertex AI API enabled and a service account key
- **Daily.co** account and API key
- **Xcode 15+** (for iOS/Watch apps)

## Setup & Testing Instructions

### 1. Clone the repository

```bash
git clone https://github.com/fabianferno/pace-pilot.git
cd pace-pilot
```

### 2. Backend (Python)

```bash
cd pacepilot-server

# Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy and fill in environment variables
cp .env.example .env   # or create .env manually — see below
```

Create a `.env` file with the following:

```env
MONGODB_URI=mongodb+srv://...
MONGODB_DB_NAME=pacepilot_db
GCP_PROJECT_ID=your-gcp-project-id
GCP_REGION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
DAILY_API_KEY=your-daily-api-key
JWT_SECRET=your-jwt-secret
APP_ENV=development

# Optional integrations
STRAVA_CLIENT_ID=...
STRAVA_CLIENT_SECRET=...
STRAVA_REDIRECT_URI=...
GOOGLE_CALENDAR_CLIENT_ID=...
GOOGLE_CALENDAR_CLIENT_SECRET=...
```

**Start the server:**

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Verify it's running:**

```bash
curl http://localhost:8000/health
# Expected: {"status":"ok","service":"pacepilot-api"}
```

**Run backend tests:**

```bash
pytest
```

### 3. Landing Page (Next.js)

```bash
cd landing

# Install dependencies
pnpm install

# Run development server
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to view.

### 4. iOS App

1. Open `PacePilot/PacePilot.xcodeproj` in Xcode 15+
2. Set your development team under **Signing & Capabilities**
3. Update the backend URL in the app's configuration to point to your running server
4. Build and run on a physical device (required for HealthKit, WebRTC audio, and Watch connectivity)

> **Note:** The Apple Watch app is included in the Xcode project. To test watch features, pair a physical Apple Watch and run the `PacePilotWatch` target.

### 5. Testing the Voice Coach

1. Start the backend server (step 2)
2. Launch the iOS app on a physical device
3. Start a voice session — the app will:
   - Request a Daily room + token from the backend
   - Connect via WebRTC
   - Stream your audio to the Pipecat pipeline → Gemini Live
4. Speak to your coach — try:
   - *"Help me plan for a 5K in 8 weeks"*
   - *"Start my run"* (begins biometric streaming from Watch)
   - *"What's my heart rate?"* (triggers `get_current_biometrics` tool call)
   - *"How am I doing on pace?"* (triggers `get_run_progress` tool call)
   - *"Summarize my run"* (post-run debrief)

### API Endpoints

The backend exposes REST endpoints under these base paths:

| Path | Description |
|------|-------------|
| `GET /health` | Health check |
| `/api/auth` | Authentication (register, login) |
| `/api/users` | User profile management |
| `/api/plans` | Training plan CRUD |
| `/api/workouts` | Workout management |
| `/api/runs` | Run session data |
| `/api/voice` | Voice session management, biometric ingestion |
| `/api/communities` | Community features |
| `/api/strava` | Strava OAuth + sync |
| `/api/calendar` | Google Calendar integration |
| `/api/notifications` | Push notifications |

Interactive API docs are available at [http://localhost:8000/docs](http://localhost:8000/docs) when the server is running.

## Project Structure

```
pace-pilot/
├── pacepilot-server/          # Python backend
│   ├── api/routes/            # FastAPI route handlers
│   ├── db/repositories/       # MongoDB repository pattern
│   ├── services/              # Business logic (plans, pace calc, Strava, calendar)
│   ├── voice/                 # Voice agent code
│   │   ├── tools/             # 16 Gemini tool definitions + handlers
│   │   ├── system_prompts/    # Per-session-type prompts
│   │   └── pipeline.py        # Pipecat pipeline definition
│   ├── tests/                 # pytest test suite
│   └── main.py                # FastAPI app entrypoint
├── PacePilot/                 # iOS app (Swift)
│   ├── Features/              # Feature modules (Onboarding, Home, ActiveRun, etc.)
│   ├── Core/                  # Networking, services, models
│   └── Shared/                # Watch ↔ Phone shared code
├── landing/                   # Next.js landing page
└── PRD.md                     # Product Requirements Document
```

## License

MIT
