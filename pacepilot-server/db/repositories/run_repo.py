from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import CommunityRunDB


def _aware(doc: dict) -> dict:
    return {
        k: v.replace(tzinfo=timezone.utc) if isinstance(v, datetime) and v.tzinfo is None else v
        for k, v in doc.items()
    }


class RunRepository:
    def __init__(self):
        self.col = get_db()["community_runs"]

    async def discover(self, limit: int = 50) -> List[CommunityRunDB]:
        query = {"date": {"$gte": datetime.now(timezone.utc)}}
        cursor = self.col.find(query).sort("date", 1).limit(limit)
        return [CommunityRunDB(**_aware(doc)) async for doc in cursor]

    async def get_by_id(self, run_id: str) -> Optional[CommunityRunDB]:
        doc = await self.col.find_one({"_id": ObjectId(run_id)})
        return CommunityRunDB(**_aware(doc)) if doc else None

    async def rsvp(self, run_id: str, user_id: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(run_id)},
            {"$addToSet": {"rsvp_user_ids": user_id}}
        )

    async def unrsvp(self, run_id: str, user_id: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(run_id)},
            {"$pull": {"rsvp_user_ids": user_id}}
        )

    async def create(self, data: dict) -> CommunityRunDB:
        result = await self.col.insert_one(data)
        doc = await self.col.find_one({"_id": result.inserted_id})
        if doc is None:
            raise RuntimeError(f"Run not found after insert (id={result.inserted_id})")
        return CommunityRunDB(**_aware(doc))
