from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository
from db.repositories.workout_repo import WorkoutRepository
from services.calendar_service import CalendarService

router = APIRouter()


class SyncRequest(BaseModel):
    workout_ids: List[str]


@router.post("/sync")
async def sync_to_calendar(body: SyncRequest, user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    if not user or not user.google_calendar_token:
        raise HTTPException(status_code=400, detail="Google Calendar not connected")
    workout_repo = WorkoutRepository()
    svc = CalendarService()
    for wid in body.workout_ids:
        workout = await workout_repo.get_by_id(wid)
        if workout:
            await svc.create_event(user.google_calendar_token, {
                "scheduled_date": workout.scheduled_date.isoformat(),
                "type": workout.type,
                "target_distance_km": workout.target_distance_km,
                "target_pace_zone": workout.target_pace_zone,
            })
    return {"synced": len(body.workout_ids)}
