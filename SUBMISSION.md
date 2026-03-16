# PacePilot — Gemini Live Agent Hackathon Submission

---

## Elevator Pitch

A voice-first AI running coach powered by Gemini Live. It talks to you mid-run, monitors your heart rate and pace via Apple Watch, and adapts coaching in real time.

---

## About the Project

### Inspiration

Every runner knows the feeling: you're 3 km into a tempo run, your heart rate is climbing, and you have no idea if you should slow down or push through. Traditional running apps give you a plan and leave you alone. Coaching apps throw notifications at a screen you can't look at mid-stride.

We asked: **what if your coach could actually talk to you while you run?**

The moment Google announced Gemini Live with native audio support and function calling, we knew this was the missing piece. A real-time, voice-native AI that can simultaneously hold a conversation, call tools to check your biometrics, and make coaching decisions — all with sub-second latency. That's not a chatbot. That's a coach.

### What It Does

PacePilot is a complete AI running coach experience across three platforms:

- **Conversational onboarding** — no forms. You talk to your coach about your goals, experience, and race ambitions. It builds your training plan from the conversation.
- **Live mid-run coaching** — the agent monitors your heart rate, pace, cadence, and GPS via Apple Watch sensors streamed every 3 seconds. It proactively speaks up when you drift out of zone:
  > *"Your heart rate just hit 172 — that's Zone 4. This is supposed to be an easy run. Let's bring it down to around 145. Try slowing your cadence a bit."*
- **Post-run analysis** — debrief your run conversationally. The agent pulls your splits, HR curve, and compares against your plan.
- **Race prep, calendar sync, Strava integration** — all accessible by voice.

### How We Built It

The architecture has three layers, all communicating in real time:

**1. Voice Pipeline (Server-Side)**

The core insight: Gemini Live runs server-side, not on the phone. We use [Pipecat](https://github.com/pipecat-ai/pipecat) as the orchestration framework to wire together:

$$\text{iOS (WebRTC audio)} \xrightarrow{\text{Daily transport}} \text{Pipecat} \xrightarrow{\text{WebSocket}} \text{Gemini Live on Vertex AI}$$

Pipecat manages the full duplex audio pipeline — VAD, 16-bit PCM encoding, and critically, the **function calling bridge**. When Gemini wants to know your heart rate, it calls `get_current_biometrics`, and our `RunContextProcessor` injects the latest sensor data from the watch.

We declared 16 tools across domains: biometrics, training plans, run history, social/community, calendar, race discovery, and user profile — giving Gemini deep agency over the coaching experience.

**2. iOS App (Swift/UIKit + SwiftUI)**

The app manages the voice session lifecycle: requests a Daily room token from our backend, connects via WebRTC, and streams audio bidirectionally. During active runs, it aggregates watch sensor data and POSTs biometric payloads to the server every 5 seconds.

**3. Apple Watch (SwiftUI/WatchKit)**

The watch is the sensor hub — heart rate, pace, GPS, cadence via HealthKit workout sessions. It streams to the phone over WatchConnectivity every 3 seconds and receives haptic trigger commands back (zone alerts, interval cues).

**Key technical decisions:**

- **Tool-first coaching**: The system prompt explicitly forbids Gemini from guessing biometrics. All claims about pace, HR, and distance must come from tool calls. This prevents hallucinated coaching advice.
- **Context injection over RAG**: Rather than retrieval, we inject real-time sensor data directly into the Pipecat pipeline context. The agent always has current biometrics without needing to search.
- **Pace zones via VDOT**: Training zones are calculated using Daniels' VDOT tables from the runner's benchmark race time — the gold standard in running science:

$$\text{VDOT} = f(\text{race distance}, \text{race time})$$
$$\text{Easy pace} = g(\text{VDOT}), \quad \text{Tempo pace} = h(\text{VDOT}), \quad \ldots$$

### Challenges We Faced

- **Latency budget**: Mid-run coaching needs to feel instant. We optimized the full pipeline — WebRTC transport, Pipecat processing, Gemini inference — to keep voice response latency under 2 seconds. Server-side Gemini Live was key; routing audio through the phone to a cloud API would have added unacceptable delay.
- **Biometric freshness**: Sensor data goes stale fast when you're running. We built a dual-stream architecture (watch → phone @ 3s, phone → server @ 5s) with timestamps so the agent knows data age and can caveat advice accordingly.
- **Session type management**: The agent behaves very differently during onboarding vs. an active run vs. post-run debrief. We maintain 5 distinct system prompts (`onboarding`, `pre_run`, `active_run`, `post_run`, `general`) and swap them based on session state.
- **Tool reliability**: With 16 tools available, we had to carefully design tool descriptions and enforce strict output schemas so Gemini calls the right tool at the right time — especially under the time pressure of a live run.

### What We Learned

- Gemini Live's native audio mode with function calling is genuinely transformative for real-time applications. The ability to maintain a natural conversation while simultaneously executing tool calls changes what's possible.
- Pipecat is an excellent abstraction for voice agent pipelines — it let us focus on coaching logic rather than audio plumbing.
- Voice-first UX requires rethinking everything. You can't show a loading spinner. Silence IS the loading state, and it needs to be short.

---

## Built With

| Category | Technologies |
|----------|-------------|
| **AI / Voice** | Google Gemini Live (gemini-2.5-flash-native-audio-preview), Vertex AI, Pipecat |
| **Backend** | Python 3.12+, FastAPI, Motor (async MongoDB) |
| **Real-Time Transport** | WebRTC via Daily.co |
| **Database** | MongoDB |
| **iOS App** | Swift, UIKit, SwiftUI, Combine, HealthKit, CoreLocation, EventKit |
| **Watch App** | SwiftUI, WatchKit, WatchConnectivity, HealthKit |
| **Landing Page** | Next.js, TypeScript, Tailwind CSS |
| **Cloud** | Google Cloud Platform (Vertex AI, Service Accounts) |
| **Integrations** | Strava API, Google Calendar API, Apple HealthKit, Apple EventKit |
| **Auth** | JWT, Google Service Account (GCP), OAuth 2.0 (Strava) |

---

## Try It Out

| Link | Description |
|------|-------------|
| [GitHub Repository](https://github.com/fabianferno/pace-pilot) | Full source code — backend, iOS app, watch app, landing page |
| [Landing Page](https://pacepilot.vercel.app) | Project website |
<!-- | [Video Demo](TODO) | 3-minute walkthrough of a live coaching session | -->
<!-- | [TestFlight](TODO) | iOS beta (if available) | -->

---

## Project Media

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│                                                                 │
│   ┌────────────────┐  WatchConnectivity  ┌──────────────────┐  │
│   │   iOS App       │◄──────────────────►│  Apple Watch App  │  │
│   │  (Swift/UIKit)  │    HR, pace, GPS   │  (SwiftUI)        │  │
│   │                 │    @ 3s intervals   │  watchOS 10+      │  │
│   └───────┬─────────┘                    └──────────────────┘  │
│           │                                                     │
│           │ WebRTC Audio (bidirectional)                         │
│           │ REST API (data, auth, plans)                        │
│           │ Biometric POST @ 5s                                 │
└───────────┼─────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND LAYER                              │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              FastAPI + Pipecat Pipeline                   │   │
│   │                                                         │   │
│   │   ┌─────────┐    ┌──────────────┐    ┌──────────────┐   │   │
│   │   │ REST    │    │ WebRTC       │    │ WebSocket    │   │   │
│   │   │ Routes  │    │ (Daily.co)   │    │ Handler      │   │   │
│   │   └────┬────┘    └──────┬───────┘    └──────┬───────┘   │   │
│   │        │                │                   │           │   │
│   │        ▼                ▼                   ▼           │   │
│   │   ┌─────────────────────────────────────────────────┐   │   │
│   │   │          Pipecat Voice Pipeline                   │   │   │
│   │   │                                                 │   │   │
│   │   │  Audio In ──► RunContextProcessor ──► Gemini    │   │   │
│   │   │               (injects biometrics)    Live      │   │   │
│   │   │                                      (S2S)     │   │   │
│   │   │  Audio Out ◄── Voice Response ◄────── + 16     │   │   │
│   │   │                                      Tools     │   │   │
│   │   └─────────────────────────────────────────────────┘   │   │
│   │        │                                                │   │
│   │        ▼                                                │   │
│   │   ┌──────────┐  ┌───────────┐  ┌────────────────┐      │   │
│   │   │ Plan     │  │ Analytics │  │ Social/Community│      │   │
│   │   │ Engine   │  │ Service   │  │ Service         │      │   │
│   │   └────┬─────┘  └─────┬─────┘  └───────┬────────┘      │   │
│   │        └───────────────┼────────────────┘               │   │
│   └────────────────────────┼────────────────────────────────┘   │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                      MongoDB                             │   │
│   │  users │ training_plans │ workouts │ run_sessions        │   │
│   │  communities │ leaderboards │ races │ agent_sessions     │   │
│   └─────────────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────────┘
                          │
            ┌─────────────┼─────────────┐
            ▼                           ▼
┌──────────────────────┐  ┌──────────────────────────┐
│  Google Cloud (GCP)  │  │  Third-Party APIs         │
│                      │  │                          │
│  Vertex AI           │  │  Strava API              │
│  Gemini Live API     │  │  Apple HealthKit         │
│  Service Account     │  │  Google Calendar API     │
│  Auth                │  │  Race Discovery          │
└──────────────────────┘  └──────────────────────────┘
```

### Voice Pipeline Detail

```
┌──────────┐     ┌──────────┐     ┌─────────────┐     ┌─────────────┐
│  Apple   │ BLE │  iPhone  │WebRTC│  Pipecat    │ WS  │ Gemini Live │
│  Watch   ├────►│  App     ├─────►│  Server     ├────►│ (Vertex AI) │
│          │     │          │◄─────┤             │◄────┤             │
│ HR:152   │     │ Stream   │audio │ Context     │voice│ "Slow down, │
│ Pace:5:20│     │ biometrics│     │ Injection   │reply│  your HR is │
│ GPS:...  │     │ @ 5s     │     │ + 16 Tools  │     │  too high"  │
└──────────┘     └──────────┘     └─────────────┘     └─────────────┘
```

### Image Gallery

<!-- Add screenshots and images here -->
<!-- ![Onboarding conversation](docs/images/onboarding.png) -->
<!-- ![Active run coaching](docs/images/active-run.png) -->
<!-- ![Post-run analysis](docs/images/post-run.png) -->
<!-- ![Apple Watch companion](docs/images/watch.png) -->
<!-- ![Landing page](docs/images/landing.png) -->

### Video Demo

<!-- Embed or link your demo video here -->
<!-- [![PacePilot Demo](docs/images/demo-thumbnail.png)](https://youtube.com/watch?v=YOUR_VIDEO_ID) -->

> **TODO:** Record a 3-minute demo showing:
> 1. Conversational onboarding — talking to the coach about goals
> 2. Starting a run — watch sensors streaming, agent coaching live
> 3. Mid-run zone alert — agent reacting to HR spike in real time
> 4. Post-run debrief — reviewing splits and performance conversationally
