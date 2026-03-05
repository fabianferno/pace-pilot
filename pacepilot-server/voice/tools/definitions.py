from pipecat.adapters.schemas.function_schema import FunctionSchema
from pipecat.adapters.schemas.tools_schema import ToolsSchema

PACEPILOT_TOOLS = ToolsSchema(standard_tools=[
    FunctionSchema(name="get_current_biometrics", description="Returns real-time HR, pace, distance, cadence.", properties={}, required=[]),
    FunctionSchema(name="get_run_progress", description="Returns current run distance, elapsed time, splits.", properties={}, required=[]),
    FunctionSchema(name="get_todays_workout", description="Returns today's scheduled workout details.", properties={}, required=[]),
    FunctionSchema(name="get_recent_runs", description="Returns the last N completed runs.", properties={"count": {"type": "integer"}}, required=[]),
    FunctionSchema(name="get_personal_records", description="Returns PRs for 5K, 10K, half, marathon.", properties={}, required=[]),
    FunctionSchema(name="get_weekly_stats", description="Returns total distance and runs this week.", properties={}, required=[]),
    FunctionSchema(name="get_plan_status", description="Returns current plan phase, week, completion %.", properties={}, required=[]),
    FunctionSchema(name="get_friend_activity", description="Returns recent runs from community members.", properties={}, required=[]),
    FunctionSchema(name="get_leaderboard_position", description="Returns user's rank on weekly leaderboard.", properties={}, required=[]),
    FunctionSchema(name="find_local_races", description="Finds upcoming races filtered by distance.", properties={"distance_km": {"type": "number"}}, required=[]),
    FunctionSchema(name="schedule_run_to_calendar", description="Adds a workout to Google Calendar.", properties={"workout_id": {"type": "string"}}, required=["workout_id"]),
    FunctionSchema(name="reschedule_workout", description="Moves a workout to a different date.", properties={"workout_id": {"type": "string"}, "new_date": {"type": "string"}}, required=["workout_id", "new_date"]),
    FunctionSchema(name="update_user_profile", description="Updates user profile during onboarding.", properties={"display_name": {"type": "string"}, "weekly_mileage_goal": {"type": "number"}, "target_race_distance": {"type": "string"}, "resting_hr": {"type": "integer"}, "max_hr": {"type": "integer"}, "preferred_days": {"type": "array", "items": {"type": "integer"}}, "onboarding_complete": {"type": "boolean"}}, required=[]),
    FunctionSchema(name="generate_training_plan", description="Generates a personalised training plan.", properties={"benchmark_distance_km": {"type": "number"}, "benchmark_time_seconds": {"type": "number"}, "weeks": {"type": "integer"}, "preferred_days": {"type": "array", "items": {"type": "integer"}}}, required=[]),
    FunctionSchema(name="mark_not_feeling_well", description="Converts today's workout to easy recovery run.", properties={}, required=[]),
])
