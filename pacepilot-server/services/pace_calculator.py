import math
from db.models import PaceZones, HRZones


class PaceCalculator:
    def vdot_from_race(self, distance_km: float, time_seconds: float) -> float:
        minutes = time_seconds / 60.0
        velocity = (distance_km * 1000.0) / minutes  # metres per minute
        pct_vo2max = 0.8 + 0.1894393 * math.exp(-0.012778 * minutes) + \
                     0.2989558 * math.exp(-0.1932605 * minutes)
        vo2 = -4.60 + 0.182258 * velocity + 0.000104 * velocity ** 2
        return vo2 / pct_vo2max

    def pace_zones_from_vdot(self, vdot: float) -> PaceZones:
        def vo2_to_pace_sec_per_km(vo2: float) -> float:
            # Solve quadratic: 0.000104*v^2 + 0.182258*v - (vo2 + 4.60) = 0  (v in m/min)
            a = 0.000104
            b = 0.182258
            c = -(vo2 + 4.60)
            discriminant = b ** 2 - 4 * a * c
            v_m_per_min = (-b + math.sqrt(discriminant)) / (2 * a)
            return 60000.0 / v_m_per_min  # seconds per km

        race_vo2 = vdot
        easy      = vo2_to_pace_sec_per_km(race_vo2 * 0.65)
        marathon  = vo2_to_pace_sec_per_km(race_vo2 * 0.79)
        threshold = vo2_to_pace_sec_per_km(race_vo2 * 0.86)
        interval  = vo2_to_pace_sec_per_km(race_vo2 * 0.97)
        rep       = vo2_to_pace_sec_per_km(race_vo2 * 1.07)

        return PaceZones(
            easy=round(easy),
            marathon=round(marathon),
            threshold=round(threshold),
            interval=round(interval),
            repetition=round(rep),
        )

    def hr_zones(self, resting_hr: int, max_hr: int) -> HRZones:
        hrr = max_hr - resting_hr

        def karvonen(pct: float) -> int:
            return round(resting_hr + pct * hrr)

        return HRZones(
            zone1_max=karvonen(0.60),
            zone2_max=karvonen(0.70),
            zone3_max=karvonen(0.80),
            zone4_max=karvonen(0.90),
            zone5_max=max_hr,
        )
