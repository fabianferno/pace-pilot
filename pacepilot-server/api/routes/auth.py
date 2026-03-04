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


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str
    onboarding_complete: bool


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
        onboarding_complete = False
    else:
        user_id = str(user.id)
        onboarding_complete = user.onboarding_complete

    return AuthResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
        user_id=user_id,
        onboarding_complete=onboarding_complete,
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
