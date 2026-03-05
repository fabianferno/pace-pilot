import httpx
from config.settings import get_settings

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
