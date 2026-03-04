from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from api.middleware.auth import get_current_user_id
from db.repositories.run_repo import RunRepository
from db.models import RunSessionDB

router = APIRouter()


class NewRunRequest(BaseModel):
    workout_id: Optional[str] = None
    started_at: datetime
    ended_at: datetime
    distance_km: float
    duration_seconds: int
    avg_pace_seconds_per_km: float
    avg_heart_rate: int
    max_heart_rate: int
    calories: int
    elevation_gain_meters: float = 0.0
    splits: list = []
    gps_track: list = []


@router.post("")
async def save_run(body: NewRunRequest, user_id: str = Depends(get_current_user_id)):
    repo = RunRepository()
    run = RunSessionDB(user_id=user_id, **body.model_dump())
    run_id = await repo.create(run)
    return {"id": run_id}


@router.get("")
async def list_runs(
    user_id: str = Depends(get_current_user_id),
    limit: int = Query(20, le=100),
    skip: int = 0,
):
    repo = RunRepository()
    runs = await repo.list_for_user(user_id, limit=limit, skip=skip)
    return [r.model_dump(by_alias=False) for r in runs]


@router.get("/recent")
async def recent_runs(count: int = Query(5, le=20), user_id: str = Depends(get_current_user_id)):
    repo = RunRepository()
    runs = await repo.get_recent(user_id, count=count)
    return [r.model_dump(by_alias=False) for r in runs]


@router.get("/{run_id}")
async def get_run(run_id: str, user_id: str = Depends(get_current_user_id)):
    repo = RunRepository()
    run = await repo.get_by_id(run_id)
    if not run or run.user_id != user_id:
        raise HTTPException(status_code=404, detail="Run not found")
    return run.model_dump(by_alias=False)
