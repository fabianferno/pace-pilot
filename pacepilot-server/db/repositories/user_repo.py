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

    async def upsert_device_token(self, user_id: str, token: str, platform: str) -> None:
        """Atomically replace the device token for a given platform using an aggregation pipeline update."""
        now = datetime.utcnow()
        await self.col.update_one(
            {"_id": ObjectId(user_id)},
            [
                {
                    "$set": {
                        "device_tokens": {
                            "$concatArrays": [
                                {
                                    "$filter": {
                                        "input": {"$ifNull": ["$device_tokens", []]},
                                        "cond": {"$ne": ["$$this.platform", platform]},
                                    }
                                },
                                [{"token": token, "platform": platform, "updated_at": now}],
                            ]
                        },
                        "updated_at": now,
                    }
                }
            ],
        )

    async def remove_device_token(self, user_id: str, token: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(user_id)},
            {"$pull": {"device_tokens": {"token": token}}, "$set": {"updated_at": datetime.utcnow()}}
        )

    async def update_notification_preferences(self, user_id: str, prefs: dict) -> None:
        await self.col.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": {"notification_preferences": prefs, "updated_at": datetime.utcnow()}}
        )

    async def get_users_with_tokens(self, user_ids: list[str]) -> list[UserDB]:
        cursor = self.col.find({
            "_id": {"$in": [ObjectId(uid) for uid in user_ids]},
            "device_tokens.0": {"$exists": True},
        })
        return [UserDB(**doc) async for doc in cursor]
