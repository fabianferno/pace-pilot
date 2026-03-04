from __future__ import annotations
import asyncio
import httpx
from datetime import datetime
from typing import Optional, Dict, List, Tuple
from config.settings import get_settings
from db.repositories.agent_session_repo import AgentSessionRepository
from db.models import AgentSessionDB
from voice.context.biometric_store import BiometricStore, BiometricSnapshot

_active_pipelines: Dict[str, asyncio.Task] = {}
_transcripts: Dict[str, list] = {}


async def create_daily_room() -> Tuple[str, str, str]:
    settings = get_settings()
    async with httpx.AsyncClient() as client:
        room_resp = await client.post(
            "https://api.daily.co/v1/rooms",
            headers={"Authorization": f"Bearer {settings.DAILY_API_KEY}"},
            json={"properties": {"exp": int(datetime.utcnow().timestamp()) + 3600}},
        )
        room_resp.raise_for_status()
        room_data = room_resp.json()
        room_url = room_data["url"]
        room_name = room_data["name"]

        bot_token_resp = await client.post(
            "https://api.daily.co/v1/meeting-tokens",
            headers={"Authorization": f"Bearer {settings.DAILY_API_KEY}"},
            json={"properties": {"room_name": room_name, "is_owner": True}},
        )
        bot_token_resp.raise_for_status()
        bot_token = bot_token_resp.json()["token"]

        client_token_resp = await client.post(
            "https://api.daily.co/v1/meeting-tokens",
            headers={"Authorization": f"Bearer {settings.DAILY_API_KEY}"},
            json={"properties": {"room_name": room_name}},
        )
        client_token_resp.raise_for_status()
        client_token = client_token_resp.json()["token"]

    return room_url, bot_token, client_token


async def start_session(user_id: str, session_type: str) -> dict:
    room_url, bot_token, client_token = await create_daily_room()
    repo = AgentSessionRepository()
    session = AgentSessionDB(user_id=user_id, session_type=session_type, daily_room_url=room_url)
    session_id = await repo.create(session)

    from voice.pipeline import run_pipeline
    task = asyncio.create_task(
        run_pipeline(session_id=session_id, user_id=user_id,
                     session_type=session_type, room_url=room_url, bot_token=bot_token)
    )
    _active_pipelines[session_id] = task
    _transcripts[session_id] = []

    return {"session_id": session_id, "room_url": room_url, "token": client_token}


async def update_biometrics(session_id: str, heart_rate: float, pace_seconds_per_km: float,
                             distance_km: float, elapsed_seconds: int) -> None:
    await BiometricStore.update(session_id, BiometricSnapshot(
        heart_rate=heart_rate,
        pace_seconds_per_km=pace_seconds_per_km,
        distance_km=distance_km,
        elapsed_seconds=elapsed_seconds,
    ))


async def end_session(session_id: str) -> dict:
    task = _active_pipelines.pop(session_id, None)
    if task:
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass

    transcript = _transcripts.pop(session_id, [])
    repo = AgentSessionRepository()
    from db.models import TranscriptEntry
    entries = [TranscriptEntry(**t) for t in transcript]
    await repo.end_session(session_id, entries)
    await BiometricStore.clear(session_id)

    return {"session_id": session_id, "transcript_entries": len(entries)}
