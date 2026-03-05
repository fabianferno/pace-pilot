from datetime import datetime
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import RaceDB


class RaceRepository:
    def __init__(self):
        self.col = get_db()["races"]

    async def discover(self, distance_km: Optional[float] = None, limit: int = 20) -> List[RaceDB]:
        query: dict = {"date": {"$gte": datetime.utcnow()}}
        if distance_km:
            query["distance_km"] = {"$gte": distance_km - 1, "$lte": distance_km + 1}
        cursor = self.col.find(query).sort("date", 1).limit(limit)
        return [RaceDB(**doc) async for doc in cursor]

    async def get_by_id(self, race_id: str) -> Optional[RaceDB]:
        doc = await self.col.find_one({"_id": ObjectId(race_id)})
        return RaceDB(**doc) if doc else None

    async def mark_interest(self, race_id: str, user_id: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(race_id)},
            {"$addToSet": {"interested_user_ids": user_id}}
        )

    async def create(self, data: dict) -> RaceDB:
        result = await self.col.insert_one(data)
        doc = await self.col.find_one({"_id": result.inserted_id})
        return RaceDB(**doc)
