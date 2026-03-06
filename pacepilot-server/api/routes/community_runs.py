from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
from api.middleware.auth import get_current_user_id
from services.community_run_service import CommunityRunService

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


@router.post("", status_code=201)
async def create_run(body: CreateRunRequest, user_id: str = Depends(get_current_user_id)):
    svc = CommunityRunService()
    data = body.model_dump()
    data["rsvp_user_ids"] = []
    run = await svc.create(data)
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
