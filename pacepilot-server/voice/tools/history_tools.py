from db.repositories.run_repo import RunRepository
from db.repositories.user_repo import UserRepository
from utils.formatters import format_pace


async def get_recent_runs(user_id: str, count: int = 5, **kwargs) -> list:
    repo = RunRepository()
    runs = await repo.get_recent(user_id, count=count)
    return [
        {
            "date": r.started_at.strftime("%A, %b %d"),
            "distance_km": round(r.distance_km, 2),
            "avg_pace": format_pace(r.avg_pace_seconds_per_km),
            "avg_hr": r.avg_heart_rate,
        }
        for r in runs
    ]


async def get_personal_records(user_id: str, **kwargs) -> dict:
    repo = RunRepository()
    prs = await repo.get_personal_records(user_id)
    return {dist: format_pace(pace) for dist, pace in prs.items()}


async def get_weekly_stats(user_id: str, **kwargs) -> dict:
    repo = UserRepository()
    return await repo.get_stats(user_id)
