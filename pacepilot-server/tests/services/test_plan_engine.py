from datetime import datetime
from services.plan_engine import PlanEngine
from db.models import PaceZones


def test_generates_workouts_for_preferred_days():
    engine = PlanEngine()
    zones = PaceZones(easy=320, marathon=285, threshold=265, interval=245, repetition=230)
    workouts = engine.generate_workouts(
        user_id="u1", plan_id="p1",
        start_date=datetime(2026, 3, 9),
        weeks=4,
        preferred_days=[0, 2, 4, 6],
        pace_zones=zones,
    )
    assert len(workouts) == 16


def test_long_run_on_last_preferred_day():
    engine = PlanEngine()
    zones = PaceZones(easy=320, marathon=285, threshold=265, interval=245, repetition=230)
    workouts = engine.generate_workouts(
        user_id="u1", plan_id="p1",
        start_date=datetime(2026, 3, 9), weeks=1,
        preferred_days=[0, 3, 6],
        pace_zones=zones,
    )
    sunday_workout = next(w for w in workouts if w.scheduled_date.weekday() == 6)
    assert sunday_workout.type == "long"
