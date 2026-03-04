from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import WorkoutDB


class WorkoutRepository:
    def __init__(self):
        self.col = get_db()["workouts"]

    async def create_many(self, workouts: List[WorkoutDB]) -> List[str]:
        data = [w.model_dump(by_alias=True, exclude={"id"}) for w in workouts]
        result = await self.col.insert_many(data)
        return [str(i) for i in result.inserted_ids]

    async def get_today(self, user_id: str) -> Optional[WorkoutDB]:
        now = datetime.utcnow()
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        doc = await self.col.find_one({
            "user_id": user_id,
            "scheduled_date": {"$gte": start, "$lt": end},
            "is_skipped": False,
        })
        return WorkoutDB(**doc) if doc else None

    async def get_week(self, user_id: str) -> List[WorkoutDB]:
        now = datetime.utcnow()
        start = now - timedelta(days=now.weekday())
        start = start.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=7)
        cursor = self.col.find({
            "user_id": user_id,
            "scheduled_date": {"$gte": start, "$lt": end},
        })
        return [WorkoutDB(**doc) async for doc in cursor]

    async def get_by_plan(self, plan_id: str) -> List[WorkoutDB]:
        cursor = self.col.find({"plan_id": plan_id})
        return [WorkoutDB(**doc) async for doc in cursor]

    async def get_by_id(self, workout_id: str) -> Optional[WorkoutDB]:
        doc = await self.col.find_one({"_id": ObjectId(workout_id)})
        return WorkoutDB(**doc) if doc else None

    async def update(self, workout_id: str, updates: dict) -> None:
        await self.col.update_one({"_id": ObjectId(workout_id)}, {"$set": updates})
