from datetime import datetime, timedelta
import httpx


class CalendarService:
    async def create_event(self, access_token: str, workout: dict) -> dict:
        start = workout["scheduled_date"]
        end_time = (datetime.fromisoformat(start) + timedelta(hours=1)).isoformat() + "Z"
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                "https://www.googleapis.com/calendar/v3/calendars/primary/events",
                headers={"Authorization": f"Bearer {access_token}"},
                json={
                    "summary": f"PacePilot: {workout['type'].capitalize()} Run",
                    "description": f"{workout['target_distance_km']:.1f}km · {workout['target_pace_zone']} pace",
                    "start": {"dateTime": start + "Z", "timeZone": "UTC"},
                    "end": {"dateTime": end_time, "timeZone": "UTC"},
                },
            )
            resp.raise_for_status()
            return resp.json()
