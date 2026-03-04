from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import CommunityDB, RunSessionDB


class CommunityRepository:
    def __init__(self):
        self.col = get_db()["communities"]

    async def get_by_tier(self, tier: str) -> Optional[CommunityDB]:
        doc = await self.col.find_one({"tier": tier})
        return CommunityDB(**doc) if doc else None

    async def get_leaderboard(self, community_id: str, limit: int = 20) -> List[dict]:
        since = datetime.utcnow() - timedelta(days=7)
        pipeline = [
            {"$match": {"started_at": {"$gte": since}}},
            {"$group": {"_id": "$user_id", "weekly_distance_km": {"$sum": "$distance_km"}}},
            {"$sort": {"weekly_distance_km": -1}},
            {"$limit": limit},
        ]
        runs_col = get_db()["run_sessions"]
        results = []
        rank = 1
        async for doc in runs_col.aggregate(pipeline):
            results.append({
                "user_id": doc["_id"],
                "weekly_distance_km": doc["weekly_distance_km"],
                "rank": rank,
            })
            rank += 1
        return results

    async def get_friend_activity(self, user_id: str, limit: int = 10) -> List[dict]:
        user_doc = await get_db()["users"].find_one({"_id": ObjectId(user_id)})
        if not user_doc:
            return []
        tier = user_doc.get("community_tier", "discovery")
        members_cursor = get_db()["users"].find(
            {"community_tier": tier, "_id": {"$ne": ObjectId(user_id)}},
            {"_id": 1, "display_name": 1}
        )
        members = {str(m["_id"]): m["display_name"] async for m in members_cursor}
        if not members:
            return []
        cursor = get_db()["run_sessions"].find(
            {"user_id": {"$in": list(members.keys())}},
        ).sort("started_at", -1).limit(limit)
        results = []
        async for doc in cursor:
            run = RunSessionDB(**doc)
            results.append({
                "id": str(doc["_id"]),
                "user_id": run.user_id,
                "display_name": members.get(run.user_id, "Runner"),
                "distance_km": run.distance_km,
                "pace_seconds_per_km": run.avg_pace_seconds_per_km,
                "completed_at": run.ended_at.isoformat(),
            })
        return results
