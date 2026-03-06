from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import RunSessionDB


class RunRepository:
    def __init__(self):
        self.col = get_db()["run_sessions"]

    async def create(self, run: RunSessionDB) -> str:
        data = run.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def get_by_id(self, run_id: str) -> Optional[RunSessionDB]:
        doc = await self.col.find_one({"_id": ObjectId(run_id)})
        return RunSessionDB(**doc) if doc else None

    async def list_for_user(self, user_id: str, limit: int = 20, skip: int = 0) -> List[RunSessionDB]:
        cursor = self.col.find({"user_id": user_id}).sort("started_at", -1).skip(skip).limit(limit)
        return [RunSessionDB(**doc) async for doc in cursor]

    async def get_recent(self, user_id: str, count: int = 5) -> List[RunSessionDB]:
        cursor = self.col.find({"user_id": user_id}).sort("started_at", -1).limit(count)
        return [RunSessionDB(**doc) async for doc in cursor]

    async def get_personal_records(self, user_id: str) -> dict:
        distances = {"5km": (4.8, 5.2), "10km": (9.8, 10.2), "half": (20.9, 21.3), "marathon": (41.9, 42.3)}
        records = {}
        for name, (lo, hi) in distances.items():
            doc = await self.col.find_one(
                {"user_id": user_id, "distance_km": {"$gte": lo, "$lte": hi}},
                sort=[("avg_pace_seconds_per_km", 1)]
            )
            if doc:
                records[name] = RunSessionDB(**doc).avg_pace_seconds_per_km
        return records

    async def get_easy_run_avg_pace(self, user_id: str, weeks: int = 4) -> Optional[float]:
        since = datetime.utcnow() - timedelta(weeks=weeks)
        pipeline = [
            {"$match": {"user_id": user_id, "workout_type": "easy", "started_at": {"$gte": since}}},
            {"$group": {"_id": None, "avg_pace": {"$avg": "$avg_pace_seconds_per_km"}}},
        ]
        async for doc in self.col.aggregate(pipeline):
            return doc["avg_pace"]
        return None
