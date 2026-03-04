from datetime import datetime, timedelta
from typing import List
from db.models import WorkoutDB, WorkoutSegment, PaceZones

WEEKLY_STRUCTURE = [
    ("easy",     6.0,  "easy",      "Easy aerobic run — conversational pace"),
    ("tempo",    5.0,  "threshold", "Tempo run — comfortably hard"),
    ("interval", 4.0,  "interval",  "Track intervals — 400m repeats"),
    ("long",    12.0,  "easy",      "Long run — build aerobic base"),
]

PHASE_MULTIPLIERS = {
    "base":     [1.0, 1.05, 1.10, 0.85],
    "build":    [1.10, 1.15, 1.20, 0.90],
    "peak":     [1.15, 1.20, 1.25, 0.90],
    "taper":    [0.80, 0.65, 0.50, 1.00],
    "recovery": [0.60, 0.65, 0.70, 0.60],
}


class PlanEngine:
    def generate_workouts(
        self,
        user_id: str,
        plan_id: str,
        start_date: datetime,
        weeks: int,
        preferred_days: List[int],
        pace_zones: PaceZones,
        phase: str = "base",
    ) -> List[WorkoutDB]:
        if not preferred_days:
            preferred_days = [0, 2, 4, 6]

        preferred_days_sorted = sorted(preferred_days)
        multipliers = PHASE_MULTIPLIERS.get(phase, PHASE_MULTIPLIERS["base"])
        workouts: List[WorkoutDB] = []

        for week_idx in range(weeks):
            multiplier = multipliers[week_idx % len(multipliers)]
            week_start = start_date + timedelta(weeks=week_idx)
            n_days = len(preferred_days_sorted)
            # Always include the long run; fill remaining slots from non-long workouts
            long_entry = [d for d in WEEKLY_STRUCTURE if d[0] == "long"]
            non_long_entries = [d for d in WEEKLY_STRUCTURE if d[0] != "long"]
            if n_days >= len(WEEKLY_STRUCTURE):
                day_types_sorted = non_long_entries + long_entry
            else:
                # Take enough non-long entries to fill (n_days - 1) slots, then append long
                day_types_sorted = non_long_entries[:max(n_days - 1, 0)] + long_entry

            for i, day_of_week in enumerate(preferred_days_sorted):
                if i >= len(day_types_sorted):
                    break
                wtype, base_dist, pace_attr, desc = day_types_sorted[i]
                days_ahead = (day_of_week - week_start.weekday()) % 7
                scheduled = week_start + timedelta(days=days_ahead)
                distance = round(base_dist * multiplier, 1)
                target_pace = getattr(pace_zones, pace_attr)

                workouts.append(WorkoutDB(
                    plan_id=plan_id,
                    user_id=user_id,
                    scheduled_date=scheduled,
                    type=wtype,
                    target_distance_km=distance,
                    target_pace_zone=pace_attr,
                    segments=[WorkoutSegment(
                        distance_km=distance,
                        pace_zone=pace_attr,
                        description=desc,
                    )],
                ))

        return workouts
