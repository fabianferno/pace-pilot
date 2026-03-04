from __future__ import annotations
from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict
import asyncio


@dataclass
class BiometricSnapshot:
    heart_rate: float = 0.0
    pace_seconds_per_km: float = 0.0
    distance_km: float = 0.0
    elapsed_seconds: int = 0
    updated_at: datetime = field(default_factory=datetime.utcnow)


class BiometricStore:
    _lock = asyncio.Lock()
    _data: Dict[str, BiometricSnapshot] = {}

    @classmethod
    async def update(cls, session_id: str, snapshot: BiometricSnapshot) -> None:
        async with cls._lock:
            cls._data[session_id] = snapshot

    @classmethod
    async def get(cls, session_id: str) -> BiometricSnapshot:
        async with cls._lock:
            return cls._data.get(session_id, BiometricSnapshot())

    @classmethod
    async def clear(cls, session_id: str) -> None:
        async with cls._lock:
            cls._data.pop(session_id, None)
