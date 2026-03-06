from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository

router = APIRouter()


class UserUpdateRequest(BaseModel):
    display_name: Optional[str] = None
    weekly_mileage_goal: Optional[float] = None
    target_race_distance: Optional[str] = None
    resting_hr: Optional[int] = None
    max_hr: Optional[int] = None
    preferred_days: Optional[List[int]] = None
    onboarding_complete: Optional[bool] = None
    city: Optional[str] = None


@router.get("/me")
async def get_me(user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user.model_dump(by_alias=False)


@router.patch("/me")
async def update_me(body: UserUpdateRequest, user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    updates = body.model_dump(exclude_none=True)
    await repo.update(user_id, updates)
    return {"ok": True}


@router.get("/me/stats")
async def get_stats(user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    return await repo.get_stats(user_id)
