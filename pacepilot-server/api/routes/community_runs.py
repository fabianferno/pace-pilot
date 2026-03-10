from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
import logging
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository
from services.community_run_service import CommunityRunService
from services.notification_service import NotificationService

logger = logging.getLogger(__name__)
router = APIRouter()


class CreateRunRequest(BaseModel):
    name: str
    distance_km: float
    date: datetime
    location: str
    city: str
    latitude: float
    longitude: float


def _serialize(run, user_id: str) -> dict:
    d = run.model_dump(by_alias=False)
    d["rsvp_count"] = len(run.rsvp_user_ids)
    d["is_rsvpd_by_user"] = user_id in run.rsvp_user_ids
    return d


@router.get("/discover")
async def discover_runs(user_id: str = Depends(get_current_user_id)):
    svc = CommunityRunService()
    runs = await svc.discover()
    return [_serialize(r, user_id) for r in runs]


async def _notify_community_run_created(run_name: str, run_id: str, city: str, rsvp_user_ids: list[str]):
    """Notify community members about a new community run event."""
    try:
        if not rsvp_user_ids:
            # No existing RSVPs to notify on a brand-new run.
            # TODO: Once we have a way to look up all users in a city or nearby
            # area, notify them about this new community run.
            logger.info(
                f"Community run '{run_name}' created in {city} "
                f"(nearby-user notifications pending geo lookup)"
            )
            return

        repo = UserRepository()
        users = await repo.get_users_with_tokens(rsvp_user_ids)
        notifier = NotificationService.get_instance()

        for user in users:
            if getattr(user, "device_tokens", None):
                await notifier.send_to_user(
                    user_tokens=user.device_tokens,
                    title="New Community Run!",
                    body=f"'{run_name}' has been created in {city}. Check it out!",
                    category="community_run",
                    route=f"/community-runs/{run_id}",
                    metadata={"community_run_id": run_id},
                )
    except Exception as e:
        logger.error(f"Failed to send community run notifications: {e}")


@router.post("", status_code=201)
async def create_run(
    body: CreateRunRequest,
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_current_user_id),
):
    svc = CommunityRunService()
    data = body.model_dump()
    data["rsvp_user_ids"] = []
    run = await svc.create(data)

    run_id = str(getattr(run, "id", ""))
    background_tasks.add_task(
        _notify_community_run_created, body.name, run_id, body.city, run.rsvp_user_ids
    )

    return _serialize(run, user_id)


@router.get("/{run_id}")
async def get_run(run_id: str, user_id: str = Depends(get_current_user_id)):
    svc = CommunityRunService()
    run = await svc.get(run_id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    return _serialize(run, user_id)


@router.post("/{run_id}/rsvp", status_code=200)
async def rsvp(run_id: str, user_id: str = Depends(get_current_user_id)):
    svc = CommunityRunService()
    await svc.rsvp(run_id, user_id)
    return {"ok": True}


@router.delete("/{run_id}/rsvp", status_code=200)
async def unrsvp(run_id: str, user_id: str = Depends(get_current_user_id)):
    svc = CommunityRunService()
    await svc.unrsvp(run_id, user_id)
    return {"ok": True}
