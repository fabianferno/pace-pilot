from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from api.middleware.auth import get_current_user_id
from db.repositories.workout_repo import WorkoutRepository

router = APIRouter()


class RescheduleRequest(BaseModel):
    new_date: datetime


@router.get("/today")
async def get_today(user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    workout = await repo.get_today(user_id)
    if not workout:
        raise HTTPException(status_code=404, detail="No workout today")
    return workout.model_dump(by_alias=False)


@router.get("/week")
async def get_week(user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    return [w.model_dump(by_alias=False) for w in await repo.get_week(user_id)]


@router.patch("/{workout_id}/reschedule")
async def reschedule(workout_id: str, body: RescheduleRequest, user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    await repo.update(workout_id, {"scheduled_date": body.new_date})
    return {"ok": True}


@router.patch("/{workout_id}/skip")
async def skip(workout_id: str, user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    await repo.update(workout_id, {"is_skipped": True})
    return {"ok": True}
