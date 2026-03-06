from db.repositories.community_run_repo import CommunityRunRepository
from db.models import CommunityRunDB
from typing import List, Optional


class CommunityRunService:
    def __init__(self):
        self.repo = CommunityRunRepository()

    async def discover(self) -> List[CommunityRunDB]:
        return await self.repo.discover()

    async def get(self, run_id: str) -> Optional[CommunityRunDB]:
        return await self.repo.get_by_id(run_id)

    async def rsvp(self, run_id: str, user_id: str) -> None:
        await self.repo.rsvp(run_id, user_id)

    async def unrsvp(self, run_id: str, user_id: str) -> None:
        await self.repo.unrsvp(run_id, user_id)

    async def create(self, payload: dict) -> CommunityRunDB:
        return await self.repo.create(payload)
