def format_pace(seconds_per_km: float) -> str:
    total = int(seconds_per_km)
    return f"{total // 60}:{total % 60:02d}"


def format_duration(seconds: int) -> str:
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    if h:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"
