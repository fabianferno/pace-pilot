from datetime import datetime
from typing import Optional, List
from bson import ObjectId
from db.connection import get_db
from db.models import TrainingPlanDB


class PlanRepository:
    def __init__(self):
        self.col = get_db()["training_plans"]

    async def create(self, plan: TrainingPlanDB) -> str:
        data = plan.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def get_active(self, user_id: str) -> Optional[TrainingPlanDB]:
        doc = await self.col.find_one({"user_id": user_id, "is_active": True})
        return TrainingPlanDB(**doc) if doc else None

    async def get_by_id(self, plan_id: str) -> Optional[TrainingPlanDB]:
        doc = await self.col.find_one({"_id": ObjectId(plan_id)})
        return TrainingPlanDB(**doc) if doc else None

    async def deactivate_all(self, user_id: str) -> None:
        await self.col.update_many(
            {"user_id": user_id},
            {"$set": {"is_active": False}}
        )

    async def update(self, plan_id: str, updates: dict) -> None:
        await self.col.update_one({"_id": ObjectId(plan_id)}, {"$set": updates})
