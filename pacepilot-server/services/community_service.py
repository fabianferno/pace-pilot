from db.repositories.run_repo import RunRepository

TIER_THRESHOLDS = [
    ("elite",       0,     240),
    ("velocity",    240,   300),
    ("momentum",    300,   360),
    ("foundation",  360,   450),
    ("discovery",   450,   99999),
]


class CommunityService:
    def __init__(self):
        self.run_repo = RunRepository()

    async def compute_tier(self, user_id: str) -> str:
        avg_pace = await self.run_repo.get_easy_run_avg_pace(user_id, weeks=4)
        if avg_pace is None:
            return "discovery"
        for tier, lo, hi in TIER_THRESHOLDS:
            if lo <= avg_pace < hi:
                return tier
        return "discovery"
