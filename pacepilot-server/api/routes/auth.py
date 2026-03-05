from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from utils.apple_auth import verify_apple_identity_token
from utils.jwt_utils import create_access_token, create_refresh_token, decode_token
from db.repositories.user_repo import UserRepository
from db.models import UserDB
from config.settings import get_settings

router = APIRouter()


class AppleAuthRequest(BaseModel):
    identity_token: str
    display_name: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    email: str
    display_name: str
    community_tier: str
    onboarding_complete: bool
    strava_connected: bool
    google_calendar_connected: bool
    weekly_mileage_goal: Optional[float] = None
    target_race_distance: Optional[str] = None
    target_race_date: Optional[str] = None


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    user: UserResponse


class RefreshRequest(BaseModel):
    refresh_token: str


@router.post("/apple", response_model=AuthResponse)
async def apple_auth(body: AppleAuthRequest):
    settings = get_settings()
    try:
        claims = await verify_apple_identity_token(
            body.identity_token, settings.APPLE_APP_BUNDLE_ID
        )
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Apple token: {e}")

    apple_user_id = claims["sub"]
    email = claims.get("email", "")
    repo = UserRepository()
    user = await repo.find_by_apple_id(apple_user_id)

    if user is None:
        new_user = UserDB(
            email=email,
            display_name=body.display_name or email.split("@")[0],
            apple_user_id=apple_user_id,
        )
        user_id = await repo.create(new_user)
        user = await repo.find_by_id(user_id)

    user_id = str(user.id)
    user_response = UserResponse(
        id=user_id,
        email=user.email,
        display_name=user.display_name,
        community_tier=user.community_tier,
        onboarding_complete=user.onboarding_complete,
        strava_connected=user.strava_connected,
        google_calendar_connected=user.google_calendar_connected,
        weekly_mileage_goal=user.weekly_mileage_goal,
        target_race_distance=user.target_race_distance,
        target_race_date=user.target_race_date.isoformat() if user.target_race_date else None,
    )
    return AuthResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
        user=user_response,
    )


@router.post("/refresh")
async def refresh_token(body: RefreshRequest):
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise ValueError("Not a refresh token")
        user_id = payload["sub"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    return {
        "access_token": create_access_token(user_id),
        "refresh_token": create_refresh_token(user_id),
    }
