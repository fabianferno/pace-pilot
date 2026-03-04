from datetime import datetime
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import AgentSessionDB, TranscriptEntry


class AgentSessionRepository:
    def __init__(self):
        self.col = get_db()["agent_sessions"]

    async def create(self, session: AgentSessionDB) -> str:
        data = session.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def end_session(self, session_id: str, transcript: List[TranscriptEntry]) -> None:
        await self.col.update_one(
            {"_id": ObjectId(session_id)},
            {"$set": {
                "ended_at": datetime.utcnow(),
                "transcript": [t.model_dump() for t in transcript],
            }}
        )

    async def list_for_user(self, user_id: str, limit: int = 10) -> List[AgentSessionDB]:
        cursor = self.col.find({"user_id": user_id}).sort("started_at", -1).limit(limit)
        return [AgentSessionDB(**doc) async for doc in cursor]
