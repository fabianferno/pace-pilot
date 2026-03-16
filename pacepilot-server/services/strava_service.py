import logging
import httpx
from datetime import datetime, timedelta
from typing import Optional
from config.settings import get_settings

log = logging.getLogger(__name__)

STRAVA_TOKEN_URL = "https://www.strava.com/oauth/token"
STRAVA_API_BASE = "https://www.strava.com/api/v3"


class StravaService:
    def get_auth_url(self, user_id: str) -> str:
        s = get_settings()
        return (
            f"https://www.strava.com/oauth/authorize"
            f"?client_id={s.STRAVA_CLIENT_ID}"
            f"&redirect_uri={s.STRAVA_REDIRECT_URI}"
            f"&response_type=code"
            f"&scope=activity:read_all,activity:write"
            f"&state={user_id}"
        )

    async def exchange_code(self, code: str) -> dict:
        s = get_settings()
        async with httpx.AsyncClient() as client:
            resp = await client.post(STRAVA_TOKEN_URL, data={
                "client_id": s.STRAVA_CLIENT_ID,
                "client_secret": s.STRAVA_CLIENT_SECRET,
                "code": code,
                "grant_type": "authorization_code",
            })
            resp.raise_for_status()
            return resp.json()

    async def refresh_access_token(self, refresh_token: str) -> dict:
        """Exchange a refresh token for a new access/refresh token pair.

        Returns the Strava token response dict with keys:
        access_token, refresh_token, expires_at, etc.
        """
        s = get_settings()
        async with httpx.AsyncClient() as client:
            resp = await client.post(STRAVA_TOKEN_URL, data={
                "client_id": s.STRAVA_CLIENT_ID,
                "client_secret": s.STRAVA_CLIENT_SECRET,
                "refresh_token": refresh_token,
                "grant_type": "refresh_token",
            })
            resp.raise_for_status()
            return resp.json()

    async def get_avg_run_pace_seconds_per_km(
        self,
        access_token: str,
        weeks: int = 8,
        *,
        user_id: Optional[str] = None,
        refresh_token: Optional[str] = None,
    ) -> Optional[float]:
        since = int((datetime.utcnow() - timedelta(weeks=weeks)).timestamp())
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{STRAVA_API_BASE}/athlete/activities",
                headers={"Authorization": f"Bearer {access_token}"},
                params={"after": since, "per_page": 100},
            )
            # Attempt token refresh on 401
            if resp.status_code == 401 and refresh_token and user_id:
                access_token = await self._refresh_and_persist(user_id, refresh_token)
                resp = await client.get(
                    f"{STRAVA_API_BASE}/athlete/activities",
                    headers={"Authorization": f"Bearer {access_token}"},
                    params={"after": since, "per_page": 100},
                )
            resp.raise_for_status()
            activities = resp.json()
        paces = [
            act["moving_time"] / (act["distance"] / 1000)
            for act in activities
            if act.get("type") == "Run"
            and act.get("distance", 0) > 0
            and act.get("moving_time", 0) > 0
        ]
        return sum(paces) / len(paces) if paces else None

    async def post_activity(self, access_token: str, run: dict) -> dict:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{STRAVA_API_BASE}/activities",
                headers={"Authorization": f"Bearer {access_token}"},
                json={
                    "name": "Run with PacePilot",
                    "type": "Run",
                    "start_date_local": run["started_at"],
                    "elapsed_time": run["duration_seconds"],
                    "distance": run["distance_km"] * 1000,
                },
            )
            resp.raise_for_status()
            return resp.json()

    async def _refresh_and_persist(self, user_id: str, refresh_token: str) -> str:
        """Refresh the Strava token and persist the new tokens to the DB."""
        from db.repositories.user_repo import UserRepository

        log.info("Refreshing expired Strava token for user %s", user_id)
        token_data = await self.refresh_access_token(refresh_token)
        await UserRepository().update(user_id, {
            "strava_access_token": token_data["access_token"],
            "strava_refresh_token": token_data["refresh_token"],
        })
        return token_data["access_token"]
