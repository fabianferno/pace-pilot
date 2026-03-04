from db.repositories.user_repo import UserRepository
from db.repositories.workout_repo import WorkoutRepository


async def update_user_profile(user_id: str, **kwargs) -> dict:
    allowed = {"display_name", "weekly_mileage_goal", "target_race_distance",
               "resting_hr", "max_hr", "preferred_days", "onboarding_complete"}
    updates = {k: v for k, v in kwargs.items() if k in allowed and v is not None}
    if not updates:
        return {"ok": True, "message": "No changes to save"}
    repo = UserRepository()
    await repo.update(user_id, updates)
    return {"ok": True, "updated_fields": list(updates.keys())}


async def mark_not_feeling_well(user_id: str, **kwargs) -> dict:
    repo = WorkoutRepository()
    workout = await repo.get_today(user_id)
    if not workout:
        return {"message": "No workout today — you're already on a rest day."}
    await repo.update(str(workout.id), {
        "type": "recovery",
        "target_distance_km": min(workout.target_distance_km, 4.0),
        "target_pace_zone": "easy",
    })
    return {"ok": True, "message": "Converted today's workout to an easy 4km recovery run."}
