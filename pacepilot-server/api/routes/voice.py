import traceback
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from api.middleware.auth import get_current_user_id
from voice import session_manager
from db.repositories.agent_session_repo import AgentSessionRepository

router = APIRouter()


class CreateSessionRequest(BaseModel):
    session_type: str


class BiometricsRequest(BaseModel):
    session_id: str
    heart_rate: float
    pace_seconds_per_km: float
    distance_km: float
    elapsed_seconds: int


class EndSessionRequest(BaseModel):
    session_id: str


@router.post("/session")
async def create_session(body: CreateSessionRequest, user_id: str = Depends(get_current_user_id)):
    try:
        return await session_manager.start_session(user_id=user_id, session_type=body.session_type)
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/biometrics")
async def push_biometrics(body: BiometricsRequest, user_id: str = Depends(get_current_user_id)):
    await session_manager.update_biometrics(
        session_id=body.session_id,
        heart_rate=body.heart_rate,
        pace_seconds_per_km=body.pace_seconds_per_km,
        distance_km=body.distance_km,
        elapsed_seconds=body.elapsed_seconds,
    )
    return {"ok": True}


@router.post("/end")
async def end_session(body: EndSessionRequest, user_id: str = Depends(get_current_user_id)):
    return await session_manager.end_session(body.session_id)


@router.get("/sessions")
async def list_sessions(user_id: str = Depends(get_current_user_id)):
    repo = AgentSessionRepository()
    sessions = await repo.list_for_user(user_id)
    return [s.model_dump(by_alias=False) for s in sessions]
