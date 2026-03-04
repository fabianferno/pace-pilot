from voice.context.biometric_store import BiometricStore
from utils.formatters import format_pace, format_duration


async def get_current_biometrics(session_id: str, **kwargs) -> dict:
    snap = await BiometricStore.get(session_id)
    return {
        "heart_rate_bpm": int(snap.heart_rate),
        "pace": format_pace(snap.pace_seconds_per_km) if snap.pace_seconds_per_km else "--:--",
        "pace_seconds_per_km": snap.pace_seconds_per_km,
        "distance_km": round(snap.distance_km, 2),
        "elapsed_time": format_duration(snap.elapsed_seconds),
    }


async def get_run_progress(session_id: str, **kwargs) -> dict:
    snap = await BiometricStore.get(session_id)
    return {
        "distance_km": round(snap.distance_km, 2),
        "elapsed_seconds": snap.elapsed_seconds,
        "elapsed_time": format_duration(snap.elapsed_seconds),
        "current_pace": format_pace(snap.pace_seconds_per_km) if snap.pace_seconds_per_km else "--:--",
    }
