from fastapi import APIRouter, Depends, Query
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository
from services.strava_service import StravaService

router = APIRouter()


@router.get("/auth-url")
async def get_auth_url(user_id: str = Depends(get_current_user_id)):
    svc = StravaService()
    return {"auth_url": svc.get_auth_url()}


@router.get("/callback")
async def strava_callback(code: str = Query(...)):
    svc = StravaService()
    token_data = await svc.exchange_code(code)
    return {"strava_data": token_data}


@router.post("/sync")
async def manual_sync(user_id: str = Depends(get_current_user_id)):
    return {"ok": True, "message": "Strava sync triggered"}


@router.delete("/disconnect")
async def disconnect_strava(user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    await repo.update(user_id, {
        "strava_connected": False,
        "strava_access_token": None,
        "strava_refresh_token": None,
    })
    return {"ok": True}
