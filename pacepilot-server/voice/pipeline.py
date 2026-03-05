import asyncio
from config.settings import get_settings
from voice.system_prompts.general import SESSION_TYPE_PROMPTS
from voice.tools.definitions import PACEPILOT_TOOLS
from voice.tools import biometric_tools, plan_tools, history_tools, social_tools
from voice.tools import calendar_tools, race_tools, user_tools

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
    "find_local_races": race_tools.find_local_races,
    "update_user_profile": user_tools.update_user_profile,
    "mark_not_feeling_well": user_tools.mark_not_feeling_well,
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

        settings = get_settings()
        system_prompt = SESSION_TYPE_PROMPTS.get(session_type, SESSION_TYPE_PROMPTS["general"])

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
            voice_id="Charon",
            system_instruction=system_prompt,
            tools=PACEPILOT_TOOLS,
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
        await runner.run(task)

    except asyncio.CancelledError:
        pass
    except Exception as e:
        print(f"[Pipeline] session={session_id} error: {e}")
