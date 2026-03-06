from services.community_run_service import CommunityRunService


async def find_local_runs(user_id: str, **kwargs) -> list:
    svc = CommunityRunService()
    runs = await svc.discover()
    return [
        {
            "name": r.name,
            "distance_km": r.distance_km,
            "date": r.date.strftime("%B %d, %Y"),
            "location": r.location,
            "city": r.city,
            "rsvp_count": len(r.rsvp_user_ids),
        }
        for r in runs[:5]
    ]
