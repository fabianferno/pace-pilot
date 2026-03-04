from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime, timedelta
from typing import List
from api.middleware.auth import get_current_user_id
from db.repositories.plan_repo import PlanRepository
from db.repositories.workout_repo import WorkoutRepository
from db.repositories.user_repo import UserRepository
from db.models import TrainingPlanDB
from services.pace_calculator import PaceCalculator
from services.plan_engine import PlanEngine

router = APIRouter()


class GeneratePlanRequest(BaseModel):
    benchmark_distance_km: float = 5.0
    benchmark_time_seconds: float = 1500.0
    weeks: int = 12
    preferred_days: List[int] = [0, 2, 4, 6]


@router.post("/generate")
async def generate_plan(body: GeneratePlanRequest, user_id: str = Depends(get_current_user_id)):
    calc = PaceCalculator()
    vdot = calc.vdot_from_race(body.benchmark_distance_km, body.benchmark_time_seconds)
    pace_zones = calc.pace_zones_from_vdot(vdot)

    user_repo = UserRepository()
    user = await user_repo.find_by_id(user_id)
    hr_zones = None
    if user and user.resting_hr and user.max_hr:
        hr_zones = calc.hr_zones(user.resting_hr, user.max_hr)

    plan_repo = PlanRepository()
    await plan_repo.deactivate_all(user_id)

    start = datetime.utcnow()
    plan = TrainingPlanDB(
        user_id=user_id,
        start_date=start,
        end_date=start + timedelta(weeks=body.weeks),
        pace_zones=pace_zones,
        hr_zones=hr_zones,
    )
    plan_id = await plan_repo.create(plan)

    engine = PlanEngine()
    workouts = engine.generate_workouts(
        user_id=user_id, plan_id=plan_id, start_date=start,
        weeks=body.weeks, preferred_days=body.preferred_days, pace_zones=pace_zones,
    )
    workout_repo = WorkoutRepository()
    await workout_repo.create_many(workouts)

    return {"plan_id": plan_id, "workout_count": len(workouts)}


@router.get("/active")
async def get_active_plan(user_id: str = Depends(get_current_user_id)):
    repo = PlanRepository()
    plan = await repo.get_active(user_id)
    if not plan:
        raise HTTPException(status_code=404, detail="No active plan")
    return plan.model_dump(by_alias=False)


@router.get("/{plan_id}/workouts")
async def get_plan_workouts(plan_id: str, user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    return [w.model_dump(by_alias=False) for w in await repo.get_by_plan(plan_id)]


@router.patch("/{plan_id}")
async def update_plan(plan_id: str, body: dict, user_id: str = Depends(get_current_user_id)):
    repo = PlanRepository()
    await repo.update(plan_id, body)
    return {"ok": True}
