from services.race_service import RaceService


async def find_local_races(user_id: str, distance_km: float = None, **kwargs) -> list:
    svc = RaceService()
    races = await svc.discover(distance_km=distance_km)
    return [
        {
            "name": r.name,
            "distance_km": r.distance_km,
            "date": r.date.strftime("%B %d, %Y"),
            "location": r.location,
        }
        for r in races[:5]
    ]
