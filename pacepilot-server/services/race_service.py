from db.repositories.race_repo import RaceRepository
from db.models import RaceDB
from typing import List, Optional


class RaceService:
    def __init__(self):
        self.repo = RaceRepository()

    async def discover(self, distance_km: Optional[float] = None) -> List[RaceDB]:
        return await self.repo.discover(distance_km=distance_km)

    async def get(self, race_id: str) -> Optional[RaceDB]:
        return await self.repo.get_by_id(race_id)

    async def register_interest(self, race_id: str, user_id: str) -> None:
        await self.repo.mark_interest(race_id, user_id)
