import asyncio
from config.settings import get_settings
from voice.system_prompts.general import SESSION_TYPE_PROMPTS
from voice.tools.definitions import PACEPILOT_TOOLS, ACTIVE_RUN_TOOLS
from voice.tools import biometric_tools, plan_tools, history_tools, social_tools
from voice.tools import calendar_tools, race_tools, user_tools

async def _run_checkins(task, session_id: str, interval_seconds: int) -> None:
    """Server-side check: only queue a coaching prompt when something is actually notable.
    Biometrics are evaluated here so no token-wasting tool call is needed on the agent side."""
    from pipecat.frames.frames import InputTextRawFrame
    from voice.context.biometric_store import BiometricStore
    from utils.formatters import format_pace

    last_km_milestone = 0.0
    # Rough HR alert threshold; refined once user profile is loaded (180 bpm ~= 90% for typical runner)
    HR_ALERT_BPM = 180
    # Pace deviation threshold: fraction beyond which we alert (0.20 = 20%)
    PACE_DEVIATION = 0.20

    try:
        while True:
            await asyncio.sleep(interval_seconds)
            snap = await BiometricStore.get(session_id)

            alerts: list[str] = []

            # HR alert
            if snap.heart_rate >= HR_ALERT_BPM:
                alerts.append(f"heart rate is {int(snap.heart_rate)} bpm (very high — runner should ease back)")

            # km milestone (1, 5, 10, 15, 20, halfway is handled separately if needed)
            MILESTONES = [1, 2, 3, 4, 5, 10, 15, 20, 21.1, 42.2]
            for m in MILESTONES:
                if last_km_milestone < m <= snap.distance_km:
                    alerts.append(f"runner just crossed {m} km ({format_pace(snap.pace_seconds_per_km) if snap.pace_seconds_per_km else '--:--'} /km current pace)")
                    last_km_milestone = m
                    break

            if not alerts:
                # Nothing notable — skip entirely, no tokens spent
                continue

            alert_text = "; ".join(alerts)
            prompt = (
                f"[COACHING ALERT] Current data (do NOT call tools): {alert_text}. "
                "Give one brief coaching cue in one sentence."
            )
            await task.queue_frame(InputTextRawFrame(text=prompt))
    except asyncio.CancelledError:
        pass


TOOL_HANDLERS = {
    "get_current_biometrics": biometric_tools.get_current_biometrics,
    "get_run_progress": biometric_tools.get_run_progress,
    "get_todays_workout": plan_tools.get_todays_workout,
    "get_plan_status": plan_tools.get_plan_status,
    "generate_training_plan": plan_tools.generate_training_plan,
    "reschedule_workout": plan_tools.reschedule_workout,
    "get_recent_runs": history_tools.get_recent_runs,
    "get_personal_records": history_tools.get_personal_records,
    "get_weekly_stats": history_tools.get_weekly_stats,
    "get_friend_activity": social_tools.get_friend_activity,
    "get_leaderboard_position": social_tools.get_leaderboard_position,
    "schedule_run_to_calendar": calendar_tools.schedule_run_to_calendar,
    "find_local_runs": race_tools.find_local_runs,
    "update_user_profile": user_tools.update_user_profile,
    "mark_not_feeling_well": user_tools.mark_not_feeling_well,
}


INITIAL_GREETING_TRIGGERS = {
    "active_run": "The runner has just started their run session. Greet them with an energetic, brief coaching welcome — mention you'll be tracking their pace and heart rate.",
    "pre_run": "The runner is about to start their run. Give them a short motivating pre-run greeting and ask if they're ready.",
    "post_run": "The runner just finished their run. Give them a warm congratulatory greeting and tell them you'll review their session.",
    "onboarding": "A new user has just joined for onboarding. Welcome them warmly and introduce yourself as PacePilot.",
    "general": "The runner has connected. Give a brief, friendly greeting and ask how you can help.",
    "replan": "The runner wants to update or create their training plan. Check what you already know about them, then ask what they'd like to change.",
}


async def run_pipeline(session_id: str, user_id: str, session_type: str,
                       room_url: str, bot_token: str) -> None:
    try:
        from pipecat.pipeline.pipeline import Pipeline
        from pipecat.pipeline.runner import PipelineRunner
        from pipecat.pipeline.task import PipelineTask
        from pipecat.transports.services.daily import DailyParams, DailyTransport
        from pipecat.services.google.gemini_live import GeminiLiveVertexLLMService
        from pipecat.services.llm_service import FunctionCallParams
        from pipecat.processors.aggregators.llm_context import LLMContext
        from pipecat.processors.aggregators.llm_response_universal import LLMContextAggregatorPair
        from pipecat.frames.frames import InputTextRawFrame

        settings = get_settings()
        system_prompt = SESSION_TYPE_PROMPTS.get(session_type, SESSION_TYPE_PROMPTS["general"])
        tools = ACTIVE_RUN_TOOLS if session_type == "active_run" else PACEPILOT_TOOLS

        transport = DailyTransport(
            room_url, bot_token, "PacePilot Coach",
            DailyParams(audio_out_enabled=True, audio_in_enabled=True),
        )

        credentials = settings.GOOGLE_APPLICATION_CREDENTIALS_JSON.strip() or None
        credentials_path = settings.GOOGLE_APPLICATION_CREDENTIALS.strip() or None
        if credentials:
            credentials_path = None

        llm = GeminiLiveVertexLLMService(
            credentials=credentials,
            credentials_path=credentials_path,
            project_id=settings.GCP_PROJECT_ID,
            location=settings.GCP_REGION,
            model="google/gemini-live-2.5-flash-native-audio",
            voice_id="Aoede",
            system_instruction=system_prompt,
            tools=tools,
        )

        async def handle_tool_call(params: FunctionCallParams):
            handler = TOOL_HANDLERS.get(params.function_name)
            if handler:
                result = await handler(user_id=user_id, session_id=session_id, **params.arguments)
            else:
                result = {"error": f"Unknown tool: {params.function_name}"}
            await params.result_callback(result)

        llm.register_function(None, handle_tool_call)

        context = LLMContext()
        context_aggregator = LLMContextAggregatorPair(context)

        pipeline = Pipeline([
            transport.input(),
            context_aggregator.user(),
            llm,
            context_aggregator.assistant(),
            transport.output(),
        ])
        task = PipelineTask(pipeline)
        runner = PipelineRunner()

        greeting_trigger = INITIAL_GREETING_TRIGGERS.get(
            session_type, INITIAL_GREETING_TRIGGERS["general"]
        )

        # How often the server pushes a proactive check-in prompt (seconds).
        # 0 means no periodic check-ins for that session type.
        CHECKIN_INTERVALS = {
            "active_run": 120,
            "pre_run": 0,
            "post_run": 0,
            "onboarding": 0,
            "general": 0,
            "replan": 0,
        }
        checkin_interval = CHECKIN_INTERVALS.get(session_type, 0)

        greeting_sent = False

        @transport.event_handler("on_first_participant_joined")
        async def on_first_participant_joined(transport, participant):
            nonlocal greeting_sent
            if greeting_sent:
                return
            greeting_sent = True
            await asyncio.sleep(3)  # wait for GeminiLive + iOS audio track subscription to be ready
            await task.queue_frame(InputTextRawFrame(text=greeting_trigger))

            if checkin_interval > 0:
                asyncio.create_task(_run_checkins(task, session_id, checkin_interval))

        await runner.run(task)

    except asyncio.CancelledError:
        pass
    except Exception as e:
        print(f"[Pipeline] session={session_id} error: {e}")
