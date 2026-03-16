import logging
from db.repositories.run_repo import RunRepository
from db.repositories.user_repo import UserRepository
from services.strava_service import StravaService

log = logging.getLogger(__name__)

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
                try:
                    avg_pace = await StravaService().get_avg_run_pace_seconds_per_km(
                        user.strava_access_token,
                        weeks=8,
                        user_id=user_id,
                        refresh_token=user.strava_refresh_token,
                    )
                except Exception:
                    log.exception("Failed to fetch Strava pace for user %s", user_id)

        tier = "discovery"
        if avg_pace is not None:
            for t, lo, hi in TIER_THRESHOLDS:
                if lo <= avg_pace < hi:
                    tier = t
                    break

        # Persist computed tier so /api/users/me stays in sync
        user_repo = UserRepository()
        await user_repo.update(user_id, {"community_tier": tier})

        return tier
