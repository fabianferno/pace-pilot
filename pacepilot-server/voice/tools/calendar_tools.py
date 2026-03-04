from db.repositories.workout_repo import WorkoutRepository
from db.repositories.user_repo import UserRepository
from services.calendar_service import CalendarService


async def schedule_run_to_calendar(user_id: str, workout_id: str, **kwargs) -> dict:
    user_repo = UserRepository()
    user = await user_repo.find_by_id(user_id)
    if not user or not user.google_calendar_token:
        return {"error": "Google Calendar not connected. Ask the user to connect it in Profile settings."}
    workout_repo = WorkoutRepository()
    workout = await workout_repo.get_by_id(workout_id)
    if not workout:
        return {"error": "Workout not found"}
    svc = CalendarService()
    await svc.create_event(user.google_calendar_token, {
        "scheduled_date": workout.scheduled_date.isoformat(),
        "type": workout.type,
        "target_distance_km": workout.target_distance_km,
        "target_pace_zone": workout.target_pace_zone,
    })
    return {"ok": True, "message": f"Added {workout.type} run on {workout.scheduled_date.strftime('%A')} to your calendar."}
