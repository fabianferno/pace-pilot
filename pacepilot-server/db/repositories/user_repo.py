from datetime import datetime, timedelta
from typing import Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from db.connection import get_db
from db.models import UserDB


class UserRepository:
    def __init__(self):
        self.col: AsyncIOMotorCollection = get_db()["users"]

    async def find_by_apple_id(self, apple_user_id: str) -> Optional[UserDB]:
        doc = await self.col.find_one({"apple_user_id": apple_user_id})
        return UserDB(**doc) if doc else None

    async def find_by_id(self, user_id: str) -> Optional[UserDB]:
        doc = await self.col.find_one({"_id": ObjectId(user_id)})
        return UserDB(**doc) if doc else None

    async def create(self, user: UserDB) -> str:
        data = user.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def update(self, user_id: str, updates: dict) -> None:
        updates["updated_at"] = datetime.utcnow()
        await self.col.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": updates}
        )

    async def get_stats(self, user_id: str) -> dict:
        since = datetime.utcnow() - timedelta(days=7)
        pipeline = [
            {"$match": {"user_id": user_id, "started_at": {"$gte": since}}},
            {"$group": {
                "_id": None,
                "weekly_distance_km": {"$sum": "$distance_km"},
                "weekly_runs": {"$sum": 1},
            }},
        ]
        runs_col = get_db()["run_sessions"]
        async for doc in runs_col.aggregate(pipeline):
            return {
                "weekly_distance_km": doc["weekly_distance_km"],
                "weekly_runs": doc["weekly_runs"],
            }
        return {"weekly_distance_km": 0.0, "weekly_runs": 0}
