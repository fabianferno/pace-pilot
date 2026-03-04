from db.repositories.community_repo import CommunityRepository
from services.community_service import CommunityService
from utils.formatters import format_pace


async def get_friend_activity(user_id: str, **kwargs) -> list:
    repo = CommunityRepository()
    activities = await repo.get_friend_activity(user_id, limit=5)
    return [
        {
            "name": a["display_name"],
            "distance_km": round(a["distance_km"], 2),
            "pace": format_pace(a["pace_seconds_per_km"]),
        }
        for a in activities
    ]


async def get_leaderboard_position(user_id: str, **kwargs) -> dict:
    svc = CommunityService()
    tier = await svc.compute_tier(user_id)
    repo = CommunityRepository()
    community = await repo.get_by_tier(tier)
    if not community:
        return {"tier": tier, "rank": None}
    leaderboard = await repo.get_leaderboard(str(community.id))
    my_entry = next((e for e in leaderboard if e["user_id"] == user_id), None)
    return {
        "tier": tier,
        "rank": my_entry["rank"] if my_entry else "unranked",
        "weekly_distance_km": round(my_entry["weekly_distance_km"], 2) if my_entry else 0,
        "total_in_tier": len(leaderboard),
    }
