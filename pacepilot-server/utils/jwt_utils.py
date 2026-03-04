from __future__ import annotations
from datetime import datetime, timedelta
from typing import Optional
from jose import jwt, JWTError
from config.settings import get_settings


def create_token(payload: dict, secret: str, expire_minutes: int) -> str:
    data = payload.copy()
    data["exp"] = datetime.utcnow() + timedelta(minutes=expire_minutes)
    return jwt.encode(data, secret, algorithm="HS256")


def create_access_token(user_id: str, secret: Optional[str] = None) -> str:
    settings = get_settings()
    s = secret or settings.JWT_SECRET
    return create_token(
        {"sub": user_id, "type": "access"},
        secret=s,
        expire_minutes=settings.JWT_ACCESS_EXPIRE_MINUTES,
    )


def create_refresh_token(user_id: str) -> str:
    settings = get_settings()
    return create_token(
        {"sub": user_id, "type": "refresh"},
        secret=settings.JWT_SECRET,
        expire_minutes=settings.JWT_REFRESH_EXPIRE_DAYS * 24 * 60,
    )


def decode_token(token: str, secret: Optional[str] = None) -> dict:
    settings = get_settings()
    s = secret or settings.JWT_SECRET
    try:
        return jwt.decode(token, s, algorithms=["HS256"])
    except JWTError as e:
        raise ValueError(f"Invalid token: {e}")
