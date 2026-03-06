from fastapi import APIRouter, Depends, Query
from fastapi.responses import RedirectResponse
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository
from services.strava_service import StravaService
from services.community_service import CommunityService

router = APIRouter()


@router.get("/auth-url")
async def get_auth_url(user_id: str = Depends(get_current_user_id)):
    svc = StravaService()
    return {"auth_url": svc.get_auth_url(user_id)}


@router.get("/callback")
async def strava_callback(code: str = Query(...), state: str = Query(...)):
    svc = StravaService()
    token_data = await svc.exchange_code(code)
    repo = UserRepository()
    await repo.update(state, {
        "strava_connected": True,
        "strava_access_token": token_data["access_token"],
        "strava_refresh_token": token_data["refresh_token"],
        "strava_token_expires_at": token_data["expires_at"],
    })
    tier = await CommunityService().compute_tier(state)
    await repo.update(state, {"community_tier": tier})
    return RedirectResponse(url="pacepilot://strava-connected")


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
