from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import RaceDB


def _make_datetimes_aware(doc: dict) -> dict:
    """Motor returns naive UTC datetimes from MongoDB; attach UTC tzinfo so
    Pydantic serialises them with an explicit timezone offset."""
    return {
        k: v.replace(tzinfo=timezone.utc) if isinstance(v, datetime) and v.tzinfo is None else v
        for k, v in doc.items()
    }


class RaceRepository:
    def __init__(self):
        self.col = get_db()["races"]

    async def discover(self, distance_km: Optional[float] = None, limit: int = 20) -> List[RaceDB]:
        query: dict = {"date": {"$gte": datetime.now(timezone.utc)}}
        if distance_km:
            query["distance_km"] = {"$gte": distance_km - 1, "$lte": distance_km + 1}
        cursor = self.col.find(query).sort("date", 1).limit(limit)
        return [RaceDB(**_make_datetimes_aware(doc)) async for doc in cursor]

    async def get_by_id(self, race_id: str) -> Optional[RaceDB]:
        doc = await self.col.find_one({"_id": ObjectId(race_id)})
        return RaceDB(**_make_datetimes_aware(doc)) if doc else None

    async def mark_interest(self, race_id: str, user_id: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(race_id)},
            {"$addToSet": {"interested_user_ids": user_id}}
        )

    async def create(self, data: dict) -> RaceDB:
        result = await self.col.insert_one(data)
        doc = await self.col.find_one({"_id": result.inserted_id})
        if doc is None:
            raise RuntimeError(f"Race document not found after insert (inserted_id={result.inserted_id})")
        return RaceDB(**_make_datetimes_aware(doc))
