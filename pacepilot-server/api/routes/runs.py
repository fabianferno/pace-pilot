from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
import logging
from api.middleware.auth import get_current_user_id
from db.repositories.run_repo import RunRepository
from db.repositories.user_repo import UserRepository
from db.models import RunSessionDB
from services.notification_service import NotificationService

logger = logging.getLogger(__name__)
router = APIRouter()


class NewRunRequest(BaseModel):
    workout_id: Optional[str] = None
    workout_type: Optional[str] = None
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


async def _notify_run_completion(user_id: str, run_id: str, distance_km: float):
    """Send social push notifications on run completion."""
    try:
        repo = UserRepository()
        user = await repo.find_by_id(user_id)
        if not user:
            return

        display_name = getattr(user, "display_name", None) or "A runner"
        notifier = NotificationService.get_instance()

        # Send a confirmation push to the runner themselves
        if getattr(user, "device_tokens", None):
            await notifier.send_to_user(
                user_tokens=user.device_tokens,
                title="Run Complete!",
                body=f"Great job on your {distance_km:.1f} km run!",
                category="run_complete",
                route=f"/runs/{run_id}",
                metadata={"run_id": run_id},
            )

        # TODO: Look up community members (same tier/community) and notify them
        # about this run completion. For now we log the intent; full community
        # member lookup will be wired in once the community membership query is
        # available in CommunityRepository.
        logger.info(
            f"Run completed by {display_name}: {distance_km:.1f} km "
            f"(community notifications pending member lookup)"
        )
    except Exception as e:
        logger.error(f"Failed to send run completion notifications: {e}")


@router.post("")
async def save_run(
    body: NewRunRequest,
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_current_user_id),
):
    if body.duration_seconds < 60:
        raise HTTPException(status_code=400, detail="Run too short: must be at least 60 seconds")
    if body.distance_km < 0.1:
        raise HTTPException(status_code=400, detail="Run too short: must be at least 100 metres")
    repo = RunRepository()
    run = RunSessionDB(user_id=user_id, **body.model_dump())
    run_id = await repo.create(run)

    # Fire-and-forget notification
    background_tasks.add_task(_notify_run_completion, user_id, run_id, body.distance_km)

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
