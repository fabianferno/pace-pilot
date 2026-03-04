from services.pace_calculator import PaceCalculator


def test_vdot_from_5k_returns_reasonable_value():
    calc = PaceCalculator()
    # 5k in ~17:30 (1050s) gives VDOT ~58 with correct m/min formula
    vdot = calc.vdot_from_race(distance_km=5.0, time_seconds=1050)
    assert 55 < vdot < 65


def test_pace_zones_from_vdot():
    calc = PaceCalculator()
    zones = calc.pace_zones_from_vdot(60)
    assert zones.easy > zones.threshold > zones.interval > zones.repetition
    assert 280 < zones.easy < 340


def test_hr_zones_from_karvonen():
    calc = PaceCalculator()
    zones = calc.hr_zones(resting_hr=55, max_hr=190)
    assert zones.zone1_max < zones.zone2_max < zones.zone3_max
