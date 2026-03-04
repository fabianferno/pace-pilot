from fastapi import APIRouter, Depends
from api.middleware.auth import get_current_user_id
from db.repositories.community_repo import CommunityRepository
from services.community_service import CommunityService

router = APIRouter()


@router.get("/me")
async def get_my_community(user_id: str = Depends(get_current_user_id)):
    svc = CommunityService()
    tier = await svc.compute_tier(user_id)
    repo = CommunityRepository()
    community = await repo.get_by_tier(tier)
    return {
        "tier": tier,
        "community": community.model_dump(by_alias=False) if community else None,
    }


@router.get("/me/leaderboard")
async def get_leaderboard(user_id: str = Depends(get_current_user_id)):
    svc = CommunityService()
    tier = await svc.compute_tier(user_id)
    repo = CommunityRepository()
    community = await repo.get_by_tier(tier)
    if not community:
        return []
    return await repo.get_leaderboard(str(community.id))


@router.get("/friends/activity")
async def get_friend_activity(user_id: str = Depends(get_current_user_id)):
    repo = CommunityRepository()
    return await repo.get_friend_activity(user_id)
