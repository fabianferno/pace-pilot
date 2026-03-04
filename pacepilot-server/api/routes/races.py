from fastapi import APIRouter, Depends, Query
from typing import Optional
from api.middleware.auth import get_current_user_id
from services.race_service import RaceService

router = APIRouter()


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
