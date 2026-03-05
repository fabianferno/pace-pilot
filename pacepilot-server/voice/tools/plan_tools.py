from datetime import datetime, timedelta
from db.repositories.plan_repo import PlanRepository
from db.repositories.user_repo import UserRepository
from db.repositories.workout_repo import WorkoutRepository
from db.models import TrainingPlanDB
from services.pace_calculator import PaceCalculator
from services.plan_engine import PlanEngine


async def get_todays_workout(user_id: str, **kwargs) -> dict:
    repo = WorkoutRepository()
    workout = await repo.get_today(user_id)
    if not workout:
        return {"message": "No workout scheduled today — it's a rest day!"}
    return {
        "type": workout.type,
        "distance_km": workout.target_distance_km,
        "pace_zone": workout.target_pace_zone,
        "segments": [s.model_dump() for s in workout.segments],
    }


async def get_plan_status(user_id: str, **kwargs) -> dict:
    repo = PlanRepository()
    plan = await repo.get_active(user_id)
    if not plan:
        return {"message": "No active training plan"}
    now = datetime.utcnow()
    total_days = (plan.end_date - plan.start_date).days
    elapsed_days = (now - plan.start_date).days
    week_number = elapsed_days // 7 + 1
    return {
        "phase": plan.phase,
        "week_number": week_number,
        "total_weeks": total_days // 7,
        "percent_complete": round(elapsed_days / total_days * 100, 1),
    }


async def generate_training_plan(user_id: str, benchmark_distance_km: float = 5.0,
                                  benchmark_time_seconds: float = 1500.0,
                                  weeks: int = 12, preferred_days: list = None, **kwargs) -> dict:
    if preferred_days is None:
        preferred_days = [0, 2, 4, 6]
    calc = PaceCalculator()
    vdot = calc.vdot_from_race(benchmark_distance_km, benchmark_time_seconds)
    pace_zones = calc.pace_zones_from_vdot(vdot)
    plan_repo = PlanRepository()
    await plan_repo.deactivate_all(user_id)
    start = datetime.utcnow()
    plan = TrainingPlanDB(user_id=user_id, start_date=start,
                          end_date=start + timedelta(weeks=weeks), pace_zones=pace_zones)
    plan_id = await plan_repo.create(plan)
    engine = PlanEngine()
    workouts = engine.generate_workouts(user_id=user_id, plan_id=plan_id, start_date=start,
                                         weeks=weeks, preferred_days=preferred_days, pace_zones=pace_zones)
    workout_repo = WorkoutRepository()
    await workout_repo.create_many(workouts)
    await UserRepository().update(user_id, {"onboarding_complete": True})
    return {
        "plan_id": plan_id,
        "workout_count": len(workouts),
        "easy_pace": f"{int(pace_zones.easy) // 60}:{int(pace_zones.easy) % 60:02d}/km",
        "first_workout_type": workouts[0].type if workouts else "easy",
    }


async def reschedule_workout(user_id: str, workout_id: str, new_date: str, **kwargs) -> dict:
    repo = WorkoutRepository()
    await repo.update(workout_id, {"scheduled_date": datetime.fromisoformat(new_date)})
    return {"ok": True, "message": f"Workout rescheduled to {new_date}"}
