from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository

router = APIRouter()


class DeviceTokenRequest(BaseModel):
    token: str
    platform: str = "ios"


class NotificationPreferencesRequest(BaseModel):
    workout_reminder: Optional[bool] = None
    post_run: Optional[bool] = None
    social: Optional[bool] = None
    race_alert: Optional[bool] = None


@router.post("/device-token")
async def register_device_token(
    body: DeviceTokenRequest,
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    await repo.upsert_device_token(user_id, body.token, body.platform)
    return {"ok": True}


@router.delete("/device-token")
async def remove_device_token(
    body: DeviceTokenRequest,
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    await repo.remove_device_token(user_id, body.token)
    return {"ok": True}


@router.get("/preferences")
async def get_notification_preferences(
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    if not user:
        return {"workout_reminder": True, "post_run": True, "social": True, "race_alert": True}
    return user.notification_preferences


@router.put("/preferences")
async def update_notification_preferences(
    body: NotificationPreferencesRequest,
    user_id: str = Depends(get_current_user_id),
):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    current = user.notification_preferences if user else {}
    updates = body.model_dump(exclude_none=True)
    merged = {**{"workout_reminder": True, "post_run": True, "social": True, "race_alert": True}, **current, **updates}
    await repo.update_notification_preferences(user_id, merged)
    return merged
