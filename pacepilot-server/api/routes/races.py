from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from api.middleware.auth import get_current_user_id
from services.race_service import RaceService

router = APIRouter()


class CreateRaceRequest(BaseModel):
    name: str
    distance_km: float
    date: datetime
    location: str
    registration_url: Optional[str] = None
    elevation_gain_meters: Optional[float] = None


@router.get("/discover")
async def discover_races(
    distance_km: Optional[float] = Query(None),
    user_id: str = Depends(get_current_user_id),
):
    svc = RaceService()
    races = await svc.discover(distance_km=distance_km)
    return [
        {**r.model_dump(by_alias=False), "is_interested_by_user": user_id in r.interested_user_ids}
        for r in races
    ]


@router.post("", status_code=201)
async def create_race(
    body: CreateRaceRequest,
    user_id: str = Depends(get_current_user_id),
):
    svc = RaceService()
    data = body.model_dump()
    data["interested_user_ids"] = []
    race = await svc.create(data)
    return {**race.model_dump(by_alias=False), "is_interested_by_user": False}


@router.get("/{race_id}")
async def get_race(race_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RaceService()
    race = await svc.get(race_id)
    return race.model_dump(by_alias=False) if race else {}


@router.post("/{race_id}/register-interest")
async def register_interest(race_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RaceService()
    await svc.register_interest(race_id, user_id)
    return {"ok": True}
