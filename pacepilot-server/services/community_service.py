from db.repositories.run_repo import RunRepository
from db.repositories.user_repo import UserRepository
from services.strava_service import StravaService

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
            user = await UserRepository().find_by_id(user_id)
            if user and user.strava_connected and user.strava_access_token:
                avg_pace = await StravaService().get_avg_run_pace_seconds_per_km(
                    user.strava_access_token, weeks=8
                )

        if avg_pace is None:
            return "discovery"
        for tier, lo, hi in TIER_THRESHOLDS:
            if lo <= avg_pace < hi:
                return tier
        return "discovery"
