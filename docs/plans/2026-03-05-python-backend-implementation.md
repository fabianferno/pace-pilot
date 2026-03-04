# PacePilot Python Backend Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete `pacepilot-server/` FastAPI backend with MongoDB, JWT auth (Apple Sign-In), Pipecat + Gemini Live voice pipeline, all 16 voice tools, and all REST API routes.

**Architecture:** FastAPI async server with Motor (async MongoDB); voice sessions run as background asyncio tasks using Pipecat pipelines connecting Daily WebRTC transport to Gemini Live on Vertex AI; tool handlers call MongoDB repositories and external APIs.

**Tech Stack:** Python 3.12+, FastAPI, Pipecat (`pipecat-ai[google,daily]`), Motor, python-jose, httpx, pydantic-settings, pytest + pytest-asyncio

---

> **Working directory for all commands:** `pacepilot-server/`

---

## Phase 1: Foundation

### Task 1: Project scaffold

**Files:**
- Create: `pacepilot-server/requirements.txt`
- Create: `pacepilot-server/.env.example`
- Create: `pacepilot-server/pytest.ini`

**Step 1: Create directory and requirements**

```bash
mkdir -p pacepilot-server/config pacepilot-server/db/repositories \
  pacepilot-server/api/middleware pacepilot-server/api/routes \
  pacepilot-server/services \
  pacepilot-server/voice/context pacepilot-server/voice/system_prompts pacepilot-server/voice/tools \
  pacepilot-server/utils \
  pacepilot-server/tests/api pacepilot-server/tests/services pacepilot-server/tests/voice
touch pacepilot-server/db/__init__.py pacepilot-server/db/repositories/__init__.py \
  pacepilot-server/api/__init__.py pacepilot-server/api/middleware/__init__.py pacepilot-server/api/routes/__init__.py \
  pacepilot-server/services/__init__.py \
  pacepilot-server/voice/__init__.py pacepilot-server/voice/context/__init__.py \
  pacepilot-server/voice/system_prompts/__init__.py pacepilot-server/voice/tools/__init__.py \
  pacepilot-server/utils/__init__.py pacepilot-server/config/__init__.py \
  pacepilot-server/tests/__init__.py pacepilot-server/tests/api/__init__.py \
  pacepilot-server/tests/services/__init__.py pacepilot-server/tests/voice/__init__.py
```

**Step 2: Write requirements.txt**

```
# pacepilot-server/requirements.txt
fastapi>=0.110.0
uvicorn[standard]>=0.29.0
pipecat-ai[google,daily]>=0.0.90
google-genai>=1.0.0
google-auth>=2.29.0
motor>=3.4.0
pymongo>=4.7.0
pydantic>=2.7.0
pydantic-settings>=2.2.0
python-dotenv>=1.0.0
httpx>=0.27.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
apscheduler>=3.10.0
pytest>=8.0.0
pytest-asyncio>=0.23.0
pytest-mock>=3.14.0
httpx>=0.27.0
```

**Step 3: Write .env.example**

```bash
# pacepilot-server/.env.example
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
MONGODB_DB_NAME=pacepilot_db
GCP_PROJECT_ID=my-project
GCP_REGION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
DAILY_API_KEY=your_daily_api_key
STRAVA_CLIENT_ID=your_strava_client_id
STRAVA_CLIENT_SECRET=your_strava_client_secret
STRAVA_REDIRECT_URI=https://yourserver.com/api/strava/callback
GOOGLE_CALENDAR_CLIENT_ID=your_gcal_client_id
GOOGLE_CALENDAR_CLIENT_SECRET=your_gcal_client_secret
JWT_SECRET=change_me_to_a_long_random_string
JWT_ALGORITHM=HS256
APP_ENV=development
APPLE_APP_BUNDLE_ID=com.yourteam.PacePilot
```

**Step 4: Write pytest.ini**

```ini
# pacepilot-server/pytest.ini
[pytest]
asyncio_mode = auto
testpaths = tests
```

**Step 5: Install dependencies**

```bash
cd pacepilot-server && pip install -r requirements.txt
```

**Step 6: Commit**

```bash
git add pacepilot-server/
git commit -m "feat: scaffold pacepilot-server Python backend project"
```

---

### Task 2: Config / Settings

**Files:**
- Create: `pacepilot-server/config/settings.py`
- Test: `pacepilot-server/tests/test_settings.py`

**Step 1: Write failing test**

```python
# tests/test_settings.py
from config.settings import Settings

def test_settings_loads_defaults():
    s = Settings(
        MONGODB_URI="mongodb://localhost",
        JWT_SECRET="secret",
        DAILY_API_KEY="key",
        GCP_PROJECT_ID="proj",
        APPLE_APP_BUNDLE_ID="com.test.App",
    )
    assert s.MONGODB_DB_NAME == "pacepilot_db"
    assert s.JWT_ALGORITHM == "HS256"
    assert s.APP_ENV == "development"
```

**Step 2: Run to verify failure**

```bash
cd pacepilot-server && pytest tests/test_settings.py -v
```
Expected: FAIL — `ModuleNotFoundError`

**Step 3: Write config/settings.py**

```python
# config/settings.py
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    MONGODB_URI: str
    MONGODB_DB_NAME: str = "pacepilot_db"
    GCP_PROJECT_ID: str
    GCP_REGION: str = "us-central1"
    GOOGLE_APPLICATION_CREDENTIALS: str = ""
    DAILY_API_KEY: str
    STRAVA_CLIENT_ID: str = ""
    STRAVA_CLIENT_SECRET: str = ""
    STRAVA_REDIRECT_URI: str = ""
    GOOGLE_CALENDAR_CLIENT_ID: str = ""
    GOOGLE_CALENDAR_CLIENT_SECRET: str = ""
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_EXPIRE_MINUTES: int = 1440   # 24h
    JWT_REFRESH_EXPIRE_DAYS: int = 30
    APP_ENV: str = "development"
    APPLE_APP_BUNDLE_ID: str

    class Config:
        env_file = ".env"
        extra = "ignore"


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

**Step 4: Run test**

```bash
pytest tests/test_settings.py -v
```
Expected: PASS

**Step 5: Commit**

```bash
git add config/settings.py tests/test_settings.py
git commit -m "feat: add pydantic Settings with env var loading"
```

---

### Task 3: Database connection + Pydantic models

**Files:**
- Create: `pacepilot-server/db/connection.py`
- Create: `pacepilot-server/db/models.py`

**Step 1: Write db/connection.py**

```python
# db/connection.py
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from config.settings import get_settings

_client: AsyncIOMotorClient | None = None


def get_client() -> AsyncIOMotorClient:
    global _client
    if _client is None:
        settings = get_settings()
        _client = AsyncIOMotorClient(settings.MONGODB_URI)
    return _client


def get_db() -> AsyncIOMotorDatabase:
    settings = get_settings()
    return get_client()[settings.MONGODB_DB_NAME]


async def close_connection():
    global _client
    if _client:
        _client.close()
        _client = None
```

**Step 2: Write db/models.py**

```python
# db/models.py
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from bson import ObjectId


class PyObjectId(str):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v, _=None):
        if isinstance(v, ObjectId):
            return str(v)
        if ObjectId.is_valid(str(v)):
            return str(v)
        raise ValueError(f"Invalid ObjectId: {v}")


# ── Users ────────────────────────────────────────────────────────────────────

class UserDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    email: str
    display_name: str
    apple_user_id: str
    community_tier: str = "discovery"
    onboarding_complete: bool = False
    strava_connected: bool = False
    strava_access_token: Optional[str] = None
    strava_refresh_token: Optional[str] = None
    google_calendar_connected: bool = False
    google_calendar_token: Optional[str] = None
    weekly_mileage_goal: Optional[float] = None
    target_race_distance: Optional[str] = None
    target_race_date: Optional[datetime] = None
    resting_hr: Optional[int] = None
    max_hr: Optional[int] = None
    preferred_days: List[int] = []   # 0=Mon … 6=Sun
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


# ── Training Plans ────────────────────────────────────────────────────────────

class PaceZones(BaseModel):
    easy: float          # seconds/km
    marathon: float
    threshold: float
    interval: float
    repetition: float

class HRZones(BaseModel):
    zone1_max: int
    zone2_max: int
    zone3_max: int
    zone4_max: int
    zone5_max: int

class TrainingPlanDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    user_id: str
    start_date: datetime
    end_date: datetime
    phase: str = "base"
    pace_zones: PaceZones
    hr_zones: Optional[HRZones] = None
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


# ── Workouts ──────────────────────────────────────────────────────────────────

class WorkoutSegment(BaseModel):
    distance_km: float
    pace_zone: str
    description: str

class WorkoutDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    plan_id: str
    user_id: str
    scheduled_date: datetime
    type: str                       # easy|tempo|interval|long|recovery|race
    target_distance_km: float
    target_pace_zone: str
    segments: List[WorkoutSegment] = []
    is_completed: bool = False
    is_skipped: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


# ── Run Sessions ──────────────────────────────────────────────────────────────

class RunSplit(BaseModel):
    km_number: int
    pace_seconds_per_km: float
    avg_heart_rate: int

class GPSPoint(BaseModel):
    latitude: float
    longitude: float
    altitude: float
    timestamp: datetime

class RunSessionDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    user_id: str
    workout_id: Optional[str] = None
    started_at: datetime
    ended_at: datetime
    distance_km: float
    duration_seconds: int
    avg_pace_seconds_per_km: float
    avg_heart_rate: int
    max_heart_rate: int
    calories: int
    elevation_gain_meters: float = 0.0
    splits: List[RunSplit] = []
    gps_track: List[GPSPoint] = []
    strava_activity_id: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


# ── Communities ───────────────────────────────────────────────────────────────

class ChallengeDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    community_id: str
    title: str
    description: str
    target_km: float
    end_date: datetime

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True

class CommunityDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    tier: str
    name: str
    member_ids: List[str] = []

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


# ── Races ─────────────────────────────────────────────────────────────────────

class RaceDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    name: str
    distance_km: float
    date: datetime
    location: str
    registration_url: Optional[str] = None
    elevation_gain_meters: Optional[float] = None
    interested_user_ids: List[str] = []

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


# ── Agent Sessions ────────────────────────────────────────────────────────────

class TranscriptEntry(BaseModel):
    role: str        # "agent" | "user"
    content: str
    timestamp: datetime

class AgentSessionDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    user_id: str
    session_type: str
    started_at: datetime = Field(default_factory=datetime.utcnow)
    ended_at: Optional[datetime] = None
    transcript: List[TranscriptEntry] = []
    daily_room_url: Optional[str] = None

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
```

**Step 3: Commit**

```bash
git add db/connection.py db/models.py
git commit -m "feat: add Motor DB connection and Pydantic models for all collections"
```

---

### Task 4: JWT utils + Apple auth validation

**Files:**
- Create: `pacepilot-server/utils/jwt_utils.py`
- Create: `pacepilot-server/utils/apple_auth.py`
- Create: `pacepilot-server/utils/formatters.py`
- Test: `pacepilot-server/tests/test_jwt_utils.py`

**Step 1: Write failing test**

```python
# tests/test_jwt_utils.py
import pytest
from utils.jwt_utils import create_access_token, decode_token

def test_roundtrip_access_token():
    token = create_access_token(user_id="abc123", secret="testsecret")
    payload = decode_token(token, secret="testsecret")
    assert payload["sub"] == "abc123"
    assert payload["type"] == "access"

def test_expired_token_raises():
    from utils.jwt_utils import create_token
    token = create_token({"sub": "abc"}, secret="s", expire_minutes=-1)
    with pytest.raises(Exception):
        decode_token(token, secret="s")
```

**Step 2: Run to verify failure**

```bash
pytest tests/test_jwt_utils.py -v
```

**Step 3: Write utils/jwt_utils.py**

```python
# utils/jwt_utils.py
from datetime import datetime, timedelta
from jose import jwt, JWTError
from config.settings import get_settings


def create_token(payload: dict, secret: str, expire_minutes: int) -> str:
    data = payload.copy()
    data["exp"] = datetime.utcnow() + timedelta(minutes=expire_minutes)
    return jwt.encode(data, secret, algorithm="HS256")


def create_access_token(user_id: str, secret: str | None = None) -> str:
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


def decode_token(token: str, secret: str | None = None) -> dict:
    settings = get_settings()
    s = secret or settings.JWT_SECRET
    try:
        return jwt.decode(token, s, algorithms=["HS256"])
    except JWTError as e:
        raise ValueError(f"Invalid token: {e}")
```

**Step 4: Write utils/apple_auth.py**

```python
# utils/apple_auth.py
import httpx
from jose import jwt
from jose.utils import base64url_decode
import json
import base64


APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"


async def verify_apple_identity_token(identity_token: str, bundle_id: str) -> dict:
    """Validate Apple identity token and return claims (sub, email)."""
    async with httpx.AsyncClient() as client:
        resp = await client.get(APPLE_KEYS_URL)
        resp.raise_for_status()
        keys = resp.json()["keys"]

    header = jwt.get_unverified_header(identity_token)
    kid = header["kid"]
    key = next((k for k in keys if k["kid"] == kid), None)
    if not key:
        raise ValueError("Apple public key not found")

    from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicNumbers
    from cryptography.hazmat.backends import default_backend

    def _b64_to_int(b64: str) -> int:
        padded = b64 + "=" * (4 - len(b64) % 4)
        return int.from_bytes(base64.urlsafe_b64decode(padded), "big")

    pub_numbers = RSAPublicNumbers(e=_b64_to_int(key["e"]), n=_b64_to_int(key["n"]))
    public_key = pub_numbers.public_key(default_backend())

    claims = jwt.decode(
        identity_token,
        public_key,
        algorithms=["RS256"],
        audience=bundle_id,
        issuer=APPLE_ISSUER,
    )
    return claims   # contains sub (apple user id), email
```

**Step 5: Write utils/formatters.py**

```python
# utils/formatters.py

def format_pace(seconds_per_km: float) -> str:
    """Format seconds/km as 'M:SS'."""
    total = int(seconds_per_km)
    return f"{total // 60}:{total % 60:02d}"


def format_duration(seconds: int) -> str:
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    if h:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"
```

**Step 6: Run tests**

```bash
pytest tests/test_jwt_utils.py -v
```
Expected: PASS

**Step 7: Commit**

```bash
git add utils/
git commit -m "feat: add JWT utilities, Apple identity token validation, and formatters"
```

---

### Task 5: Auth middleware dependency

**Files:**
- Create: `pacepilot-server/api/middleware/auth.py`
- Test: `pacepilot-server/tests/api/test_auth_middleware.py`

**Step 1: Write failing test**

```python
# tests/api/test_auth_middleware.py
import pytest
from fastapi import FastAPI
from httpx import AsyncClient, ASGITransport
from api.middleware.auth import get_current_user_id
from utils.jwt_utils import create_access_token

app = FastAPI()

@app.get("/protected")
async def protected(user_id: str = __import__('fastapi').Depends(get_current_user_id)):
    return {"user_id": user_id}

@pytest.mark.asyncio
async def test_valid_token_returns_user_id():
    token = create_access_token("user123", secret="test")
    import os; os.environ["JWT_SECRET"] = "test"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        resp = await ac.get("/protected", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200

@pytest.mark.asyncio
async def test_missing_token_returns_401():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        resp = await ac.get("/protected")
    assert resp.status_code == 401
```

**Step 2: Write api/middleware/auth.py**

```python
# api/middleware/auth.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from utils.jwt_utils import decode_token

bearer = HTTPBearer()


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
) -> str:
    try:
        payload = decode_token(credentials.credentials)
        if payload.get("type") != "access":
            raise ValueError("Not an access token")
        return payload["sub"]
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
```

**Step 3: Run test**

```bash
pytest tests/api/test_auth_middleware.py -v
```
Expected: PASS

**Step 4: Commit**

```bash
git add api/middleware/auth.py tests/api/test_auth_middleware.py
git commit -m "feat: add JWT bearer auth dependency for FastAPI routes"
```

---

## Phase 2: Repositories

### Task 6: User Repository

**Files:**
- Create: `pacepilot-server/db/repositories/user_repo.py`
- Test: `pacepilot-server/tests/test_user_repo.py`

**Step 1: Write failing test**

```python
# tests/test_user_repo.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from db.repositories.user_repo import UserRepository
from db.models import UserDB

@pytest.fixture
def mock_collection():
    col = MagicMock()
    col.find_one = AsyncMock()
    col.insert_one = AsyncMock()
    col.update_one = AsyncMock()
    return col

@pytest.fixture
def repo(mock_collection):
    r = UserRepository.__new__(UserRepository)
    r.col = mock_collection
    return r

@pytest.mark.asyncio
async def test_find_by_apple_id_returns_user(repo, mock_collection):
    mock_collection.find_one.return_value = {
        "_id": "abc", "email": "a@b.com", "display_name": "Runner",
        "apple_user_id": "appleXYZ", "community_tier": "momentum",
        "onboarding_complete": True, "strava_connected": False,
        "google_calendar_connected": False
    }
    user = await repo.find_by_apple_id("appleXYZ")
    assert user is not None
    assert user.email == "a@b.com"

@pytest.mark.asyncio
async def test_find_by_apple_id_returns_none_when_not_found(repo, mock_collection):
    mock_collection.find_one.return_value = None
    user = await repo.find_by_apple_id("nonexistent")
    assert user is None
```

**Step 2: Write db/repositories/user_repo.py**

```python
# db/repositories/user_repo.py
from datetime import datetime
from typing import Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from db.connection import get_db
from db.models import UserDB


class UserRepository:
    def __init__(self):
        self.col: AsyncIOMotorCollection = get_db()["users"]

    async def find_by_apple_id(self, apple_user_id: str) -> Optional[UserDB]:
        doc = await self.col.find_one({"apple_user_id": apple_user_id})
        return UserDB(**doc) if doc else None

    async def find_by_id(self, user_id: str) -> Optional[UserDB]:
        doc = await self.col.find_one({"_id": ObjectId(user_id)})
        return UserDB(**doc) if doc else None

    async def create(self, user: UserDB) -> str:
        data = user.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def update(self, user_id: str, updates: dict) -> None:
        updates["updated_at"] = datetime.utcnow()
        await self.col.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": updates}
        )

    async def get_stats(self, user_id: str) -> dict:
        """Return weekly distance and run count from run_sessions."""
        from datetime import timedelta
        since = datetime.utcnow() - timedelta(days=7)
        pipeline = [
            {"$match": {"user_id": user_id, "started_at": {"$gte": since}}},
            {"$group": {
                "_id": None,
                "weekly_distance_km": {"$sum": "$distance_km"},
                "weekly_runs": {"$sum": 1},
            }},
        ]
        runs_col = get_db()["run_sessions"]
        async for doc in runs_col.aggregate(pipeline):
            return {
                "weekly_distance_km": doc["weekly_distance_km"],
                "weekly_runs": doc["weekly_runs"],
            }
        return {"weekly_distance_km": 0.0, "weekly_runs": 0}
```

**Step 3: Run tests**

```bash
pytest tests/test_user_repo.py -v
```
Expected: PASS

**Step 4: Commit**

```bash
git add db/repositories/user_repo.py tests/test_user_repo.py
git commit -m "feat: add UserRepository with CRUD and weekly stats aggregation"
```

---

### Task 7: Plan + Workout Repositories

**Files:**
- Create: `pacepilot-server/db/repositories/plan_repo.py`
- Create: `pacepilot-server/db/repositories/workout_repo.py`

```python
# db/repositories/plan_repo.py
from datetime import datetime
from typing import Optional, List
from bson import ObjectId
from db.connection import get_db
from db.models import TrainingPlanDB


class PlanRepository:
    def __init__(self):
        self.col = get_db()["training_plans"]

    async def create(self, plan: TrainingPlanDB) -> str:
        data = plan.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def get_active(self, user_id: str) -> Optional[TrainingPlanDB]:
        doc = await self.col.find_one({"user_id": user_id, "is_active": True})
        return TrainingPlanDB(**doc) if doc else None

    async def get_by_id(self, plan_id: str) -> Optional[TrainingPlanDB]:
        doc = await self.col.find_one({"_id": ObjectId(plan_id)})
        return TrainingPlanDB(**doc) if doc else None

    async def deactivate_all(self, user_id: str) -> None:
        await self.col.update_many(
            {"user_id": user_id},
            {"$set": {"is_active": False}}
        )

    async def update(self, plan_id: str, updates: dict) -> None:
        await self.col.update_one({"_id": ObjectId(plan_id)}, {"$set": updates})
```

```python
# db/repositories/workout_repo.py
from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import WorkoutDB


class WorkoutRepository:
    def __init__(self):
        self.col = get_db()["workouts"]

    async def create_many(self, workouts: List[WorkoutDB]) -> List[str]:
        data = [w.model_dump(by_alias=True, exclude={"id"}) for w in workouts]
        result = await self.col.insert_many(data)
        return [str(i) for i in result.inserted_ids]

    async def get_today(self, user_id: str) -> Optional[WorkoutDB]:
        now = datetime.utcnow()
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        doc = await self.col.find_one({
            "user_id": user_id,
            "scheduled_date": {"$gte": start, "$lt": end},
            "is_skipped": False,
        })
        return WorkoutDB(**doc) if doc else None

    async def get_week(self, user_id: str) -> List[WorkoutDB]:
        now = datetime.utcnow()
        start = now - timedelta(days=now.weekday())
        start = start.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=7)
        cursor = self.col.find({
            "user_id": user_id,
            "scheduled_date": {"$gte": start, "$lt": end},
        })
        return [WorkoutDB(**doc) async for doc in cursor]

    async def get_by_plan(self, plan_id: str) -> List[WorkoutDB]:
        cursor = self.col.find({"plan_id": plan_id})
        return [WorkoutDB(**doc) async for doc in cursor]

    async def get_by_id(self, workout_id: str) -> Optional[WorkoutDB]:
        doc = await self.col.find_one({"_id": ObjectId(workout_id)})
        return WorkoutDB(**doc) if doc else None

    async def update(self, workout_id: str, updates: dict) -> None:
        await self.col.update_one({"_id": ObjectId(workout_id)}, {"$set": updates})
```

**Step 2: Commit**

```bash
git add db/repositories/plan_repo.py db/repositories/workout_repo.py
git commit -m "feat: add PlanRepository and WorkoutRepository"
```

---

### Task 8: Run + Community + Race + AgentSession Repositories

**Files:**
- Create: `pacepilot-server/db/repositories/run_repo.py`
- Create: `pacepilot-server/db/repositories/community_repo.py`
- Create: `pacepilot-server/db/repositories/race_repo.py`
- Create: `pacepilot-server/db/repositories/agent_session_repo.py`

```python
# db/repositories/run_repo.py
from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import RunSessionDB


class RunRepository:
    def __init__(self):
        self.col = get_db()["run_sessions"]

    async def create(self, run: RunSessionDB) -> str:
        data = run.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def get_by_id(self, run_id: str) -> Optional[RunSessionDB]:
        doc = await self.col.find_one({"_id": ObjectId(run_id)})
        return RunSessionDB(**doc) if doc else None

    async def list_for_user(self, user_id: str, limit: int = 20, skip: int = 0) -> List[RunSessionDB]:
        cursor = self.col.find({"user_id": user_id}).sort("started_at", -1).skip(skip).limit(limit)
        return [RunSessionDB(**doc) async for doc in cursor]

    async def get_recent(self, user_id: str, count: int = 5) -> List[RunSessionDB]:
        cursor = self.col.find({"user_id": user_id}).sort("started_at", -1).limit(count)
        return [RunSessionDB(**doc) async for doc in cursor]

    async def get_personal_records(self, user_id: str) -> dict:
        """Return best pace for common distances."""
        distances = {"5km": (4.8, 5.2), "10km": (9.8, 10.2), "half": (20.9, 21.3), "marathon": (41.9, 42.3)}
        records = {}
        for name, (lo, hi) in distances.items():
            doc = await self.col.find_one(
                {"user_id": user_id, "distance_km": {"$gte": lo, "$lte": hi}},
                sort=[("avg_pace_seconds_per_km", 1)]
            )
            if doc:
                records[name] = RunSessionDB(**doc).avg_pace_seconds_per_km
        return records

    async def get_easy_run_avg_pace(self, user_id: str, weeks: int = 4) -> Optional[float]:
        """Average easy-run pace for community tier calculation."""
        since = datetime.utcnow() - timedelta(weeks=weeks)
        pipeline = [
            {"$match": {"user_id": user_id, "workout_type": "easy", "started_at": {"$gte": since}}},
            {"$group": {"_id": None, "avg_pace": {"$avg": "$avg_pace_seconds_per_km"}}},
        ]
        async for doc in self.col.aggregate(pipeline):
            return doc["avg_pace"]
        return None
```

```python
# db/repositories/community_repo.py
from typing import List
from bson import ObjectId
from db.connection import get_db
from db.models import CommunityDB


class CommunityRepository:
    def __init__(self):
        self.col = get_db()["communities"]

    async def get_by_tier(self, tier: str) -> CommunityDB | None:
        doc = await self.col.find_one({"tier": tier})
        return CommunityDB(**doc) if doc else None

    async def get_leaderboard(self, community_id: str, limit: int = 20) -> List[dict]:
        """Weekly distance leaderboard from run_sessions."""
        from datetime import datetime, timedelta
        since = datetime.utcnow() - timedelta(days=7)
        pipeline = [
            {"$match": {"started_at": {"$gte": since}}},
            {"$group": {"_id": "$user_id", "weekly_distance_km": {"$sum": "$distance_km"}}},
            {"$sort": {"weekly_distance_km": -1}},
            {"$limit": limit},
        ]
        runs_col = get_db()["run_sessions"]
        results = []
        rank = 1
        async for doc in runs_col.aggregate(pipeline):
            results.append({
                "user_id": doc["_id"],
                "weekly_distance_km": doc["weekly_distance_km"],
                "rank": rank,
            })
            rank += 1
        return results

    async def get_friend_activity(self, user_id: str, limit: int = 10) -> List[dict]:
        """Last N runs from users in same community tier."""
        user_doc = await get_db()["users"].find_one({"_id": ObjectId(user_id)})
        if not user_doc:
            return []
        tier = user_doc.get("community_tier", "discovery")
        members_cursor = get_db()["users"].find({"community_tier": tier, "_id": {"$ne": ObjectId(user_id)}}, {"_id": 1, "display_name": 1})
        members = {str(m["_id"]): m["display_name"] async for m in members_cursor}
        if not members:
            return []
        cursor = get_db()["run_sessions"].find(
            {"user_id": {"$in": list(members.keys())}},
        ).sort("started_at", -1).limit(limit)
        results = []
        async for doc in cursor:
            run = RunSessionDB(**doc)
            results.append({
                "id": str(doc["_id"]),
                "user_id": run.user_id,
                "display_name": members.get(run.user_id, "Runner"),
                "distance_km": run.distance_km,
                "pace_seconds_per_km": run.avg_pace_seconds_per_km,
                "completed_at": run.ended_at.isoformat(),
            })
        return results

from db.models import RunSessionDB
```

```python
# db/repositories/race_repo.py
from datetime import datetime
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import RaceDB


class RaceRepository:
    def __init__(self):
        self.col = get_db()["races"]

    async def discover(self, distance_km: Optional[float] = None, limit: int = 20) -> List[RaceDB]:
        query: dict = {"date": {"$gte": datetime.utcnow()}}
        if distance_km:
            query["distance_km"] = {"$gte": distance_km - 1, "$lte": distance_km + 1}
        cursor = self.col.find(query).sort("date", 1).limit(limit)
        return [RaceDB(**doc) async for doc in cursor]

    async def get_by_id(self, race_id: str) -> Optional[RaceDB]:
        doc = await self.col.find_one({"_id": ObjectId(race_id)})
        return RaceDB(**doc) if doc else None

    async def mark_interest(self, race_id: str, user_id: str) -> None:
        await self.col.update_one(
            {"_id": ObjectId(race_id)},
            {"$addToSet": {"interested_user_ids": user_id}}
        )
```

```python
# db/repositories/agent_session_repo.py
from datetime import datetime
from typing import List, Optional
from bson import ObjectId
from db.connection import get_db
from db.models import AgentSessionDB, TranscriptEntry


class AgentSessionRepository:
    def __init__(self):
        self.col = get_db()["agent_sessions"]

    async def create(self, session: AgentSessionDB) -> str:
        data = session.model_dump(by_alias=True, exclude={"id"})
        result = await self.col.insert_one(data)
        return str(result.inserted_id)

    async def end_session(self, session_id: str, transcript: List[TranscriptEntry]) -> None:
        await self.col.update_one(
            {"_id": ObjectId(session_id)},
            {"$set": {
                "ended_at": datetime.utcnow(),
                "transcript": [t.model_dump() for t in transcript],
            }}
        )

    async def list_for_user(self, user_id: str, limit: int = 10) -> List[AgentSessionDB]:
        cursor = self.col.find({"user_id": user_id}).sort("started_at", -1).limit(limit)
        return [AgentSessionDB(**doc) async for doc in cursor]
```

**Step 2: Commit**

```bash
git add db/repositories/
git commit -m "feat: add Run, Community, Race, and AgentSession repositories"
```

---

## Phase 3: Services

### Task 9: Pace Calculator (VDOT)

**Files:**
- Create: `pacepilot-server/services/pace_calculator.py`
- Test: `pacepilot-server/tests/services/test_pace_calculator.py`

**Step 1: Write failing test**

```python
# tests/services/test_pace_calculator.py
from services.pace_calculator import PaceCalculator

def test_vdot_from_5k_returns_reasonable_value():
    calc = PaceCalculator()
    vdot = calc.vdot_from_race(distance_km=5.0, time_seconds=1200)  # 20min 5K
    assert 55 < vdot < 65

def test_pace_zones_from_vdot():
    calc = PaceCalculator()
    zones = calc.pace_zones_from_vdot(60)
    assert zones.easy > zones.threshold > zones.interval > zones.repetition
    assert 280 < zones.easy < 330   # ~5:00/km easy for VDOT 60

def test_hr_zones_from_karvonen():
    calc = PaceCalculator()
    zones = calc.hr_zones(resting_hr=55, max_hr=190)
    assert zones.zone1_max < zones.zone2_max < zones.zone3_max
```

**Step 2: Write services/pace_calculator.py**

```python
# services/pace_calculator.py
import math
from db.models import PaceZones, HRZones


class PaceCalculator:
    """VDOT-based pace zone calculator following Jack Daniels' Running Formula."""

    def vdot_from_race(self, distance_km: float, time_seconds: float) -> float:
        """Estimate VDOT from a race result."""
        minutes = time_seconds / 60.0
        velocity = distance_km / minutes  # km/min

        # Percent VO2max at race pace (Daniels' formula)
        pct_vo2max = 0.8 + 0.1894393 * math.exp(-0.012778 * minutes) + \
                     0.2989558 * math.exp(-0.1932605 * minutes)

        # VO2 at race pace
        vo2 = -4.60 + 0.182258 * velocity + 0.000104 * velocity ** 2

        return vo2 / pct_vo2max

    def pace_zones_from_vdot(self, vdot: float) -> PaceZones:
        """Return pace zones in seconds/km for a given VDOT."""
        # Training velocities as % of vDOT race velocity
        # Easy: 59-74%, Marathon: 75-84%, Threshold: 83-88%,
        # Interval: 95-100%, Repetition: 105-110%
        def vo2_to_velocity(vo2: float) -> float:
            """km/min → seconds/km"""
            km_per_min = (vo2 + 4.60) / 0.182258
            return 60.0 / km_per_min

        race_vo2 = vdot  # vdot ≈ race VO2max
        easy      = vo2_to_velocity(race_vo2 * 0.65)
        marathon  = vo2_to_velocity(race_vo2 * 0.79)
        threshold = vo2_to_velocity(race_vo2 * 0.86)
        interval  = vo2_to_velocity(race_vo2 * 0.97)
        rep       = vo2_to_velocity(race_vo2 * 1.07)

        return PaceZones(
            easy=round(easy),
            marathon=round(marathon),
            threshold=round(threshold),
            interval=round(interval),
            repetition=round(rep),
        )

    def hr_zones(self, resting_hr: int, max_hr: int) -> HRZones:
        """Karvonen formula: target HR = resting + %HRR * (max - resting)."""
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
```

**Step 3: Run tests**

```bash
pytest tests/services/test_pace_calculator.py -v
```
Expected: PASS

**Step 4: Commit**

```bash
git add services/pace_calculator.py tests/services/test_pace_calculator.py
git commit -m "feat: add VDOT-based PaceCalculator with Karvonen HR zones"
```

---

### Task 10: Plan Engine

**Files:**
- Create: `pacepilot-server/services/plan_engine.py`
- Test: `pacepilot-server/tests/services/test_plan_engine.py`

**Step 1: Write failing test**

```python
# tests/services/test_plan_engine.py
from datetime import datetime, timedelta
from services.plan_engine import PlanEngine
from db.models import PaceZones

def test_generates_workouts_for_preferred_days():
    engine = PlanEngine()
    zones = PaceZones(easy=320, marathon=285, threshold=265, interval=245, repetition=230)
    workouts = engine.generate_workouts(
        user_id="u1",
        plan_id="p1",
        start_date=datetime(2026, 3, 9),  # Monday
        weeks=4,
        preferred_days=[0, 2, 4, 6],     # Mon, Wed, Fri, Sun
        pace_zones=zones,
    )
    # 4 weeks × 4 days = 16 workouts
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
```

**Step 2: Write services/plan_engine.py**

```python
# services/plan_engine.py
from datetime import datetime, timedelta
from typing import List
from db.models import WorkoutDB, WorkoutSegment, PaceZones

WEEKLY_STRUCTURE = [
    # (type, base_distance_km, pace_zone_attr, description)
    ("easy",     6.0,  "easy",      "Easy aerobic run — conversational pace"),
    ("tempo",    5.0,  "threshold", "Tempo run — comfortably hard"),
    ("interval", 4.0,  "interval",  "Track intervals — 400m repeats"),
    ("long",    12.0,  "easy",      "Long run — build aerobic base"),
]

PHASE_MULTIPLIERS = {
    "base":     [1.0, 1.05, 1.10, 0.85],  # 4-week blocks with cutback
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
        preferred_days: List[int],   # 0=Mon…6=Sun
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
            # Assign workout types to preferred days
            # Long run always goes to last preferred day of the week
            day_types = WEEKLY_STRUCTURE[:len(preferred_days_sorted)]
            # Ensure long run is last
            day_types_sorted = sorted(
                day_types,
                key=lambda x: (x[0] == "long", WEEKLY_STRUCTURE.index(x))
            )

            for i, day_of_week in enumerate(preferred_days_sorted):
                if i >= len(day_types_sorted):
                    break
                wtype, base_dist, pace_attr, desc = day_types_sorted[i]
                scheduled = week_start + timedelta(days=(day_of_week - week_start.weekday()) % 7)
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
```

**Step 3: Run tests**

```bash
pytest tests/services/test_plan_engine.py -v
```
Expected: PASS

**Step 4: Commit**

```bash
git add services/plan_engine.py tests/services/test_plan_engine.py
git commit -m "feat: add PlanEngine with periodization and hard-easy workout distribution"
```

---

### Task 11: Community + Strava + Calendar Services

**Files:**
- Create: `pacepilot-server/services/community_service.py`
- Create: `pacepilot-server/services/strava_service.py`
- Create: `pacepilot-server/services/calendar_service.py`
- Create: `pacepilot-server/services/race_service.py`

```python
# services/community_service.py
from db.repositories.run_repo import RunRepository

TIER_THRESHOLDS = [
    ("elite",       0,     240),    # sub 4:00/km
    ("velocity",    240,   300),    # 4:00–5:00
    ("momentum",    300,   360),    # 5:00–6:00
    ("foundation",  360,   450),    # 6:00–7:30
    ("discovery",   450,   99999),  # 7:30+
]


class CommunityService:
    def __init__(self):
        self.run_repo = RunRepository()

    async def compute_tier(self, user_id: str) -> str:
        avg_pace = await self.run_repo.get_easy_run_avg_pace(user_id, weeks=4)
        if avg_pace is None:
            return "discovery"
        for tier, lo, hi in TIER_THRESHOLDS:
            if lo <= avg_pace < hi:
                return tier
        return "discovery"
```

```python
# services/strava_service.py
import httpx
from config.settings import get_settings

STRAVA_TOKEN_URL = "https://www.strava.com/oauth/token"
STRAVA_API_BASE = "https://www.strava.com/api/v3"


class StravaService:
    def get_auth_url(self) -> str:
        s = get_settings()
        return (
            f"https://www.strava.com/oauth/authorize"
            f"?client_id={s.STRAVA_CLIENT_ID}"
            f"&redirect_uri={s.STRAVA_REDIRECT_URI}"
            f"&response_type=code"
            f"&scope=activity:read_all,activity:write"
        )

    async def exchange_code(self, code: str) -> dict:
        s = get_settings()
        async with httpx.AsyncClient() as client:
            resp = await client.post(STRAVA_TOKEN_URL, data={
                "client_id": s.STRAVA_CLIENT_ID,
                "client_secret": s.STRAVA_CLIENT_SECRET,
                "code": code,
                "grant_type": "authorization_code",
            })
            resp.raise_for_status()
            return resp.json()

    async def post_activity(self, access_token: str, run: dict) -> dict:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{STRAVA_API_BASE}/activities",
                headers={"Authorization": f"Bearer {access_token}"},
                json={
                    "name": "Run with PacePilot",
                    "type": "Run",
                    "start_date_local": run["started_at"],
                    "elapsed_time": run["duration_seconds"],
                    "distance": run["distance_km"] * 1000,
                },
            )
            resp.raise_for_status()
            return resp.json()
```

```python
# services/calendar_service.py
from datetime import datetime, timedelta
import httpx


class CalendarService:
    async def create_event(self, access_token: str, workout: dict) -> dict:
        """Create a Google Calendar event for a workout."""
        start = workout["scheduled_date"]
        end_time = (datetime.fromisoformat(start) + timedelta(hours=1)).isoformat() + "Z"
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                "https://www.googleapis.com/calendar/v3/calendars/primary/events",
                headers={"Authorization": f"Bearer {access_token}"},
                json={
                    "summary": f"PacePilot: {workout['type'].capitalize()} Run",
                    "description": f"{workout['target_distance_km']:.1f}km · {workout['target_pace_zone']} pace",
                    "start": {"dateTime": start + "Z", "timeZone": "UTC"},
                    "end": {"dateTime": end_time, "timeZone": "UTC"},
                },
            )
            resp.raise_for_status()
            return resp.json()
```

```python
# services/race_service.py
from db.repositories.race_repo import RaceRepository
from db.models import RaceDB
from typing import List, Optional


class RaceService:
    def __init__(self):
        self.repo = RaceRepository()

    async def discover(self, distance_km: Optional[float] = None) -> List[RaceDB]:
        return await self.repo.discover(distance_km=distance_km)

    async def get(self, race_id: str) -> Optional[RaceDB]:
        return await self.repo.get_by_id(race_id)

    async def register_interest(self, race_id: str, user_id: str) -> None:
        await self.repo.mark_interest(race_id, user_id)
```

**Step 2: Commit**

```bash
git add services/
git commit -m "feat: add Community, Strava, Calendar, and Race services"
```

---

## Phase 4: API Routes

### Task 12: Auth routes

**Files:**
- Create: `pacepilot-server/api/routes/auth.py`
- Test: `pacepilot-server/tests/api/test_auth_routes.py`

**Step 1: Write failing test**

```python
# tests/api/test_auth_routes.py
import pytest
from fastapi import FastAPI
from httpx import AsyncClient, ASGITransport
from unittest.mock import patch, AsyncMock
from api.routes.auth import router

app = FastAPI()
app.include_router(router, prefix="/api/auth")

@pytest.mark.asyncio
async def test_apple_auth_returns_tokens_for_new_user():
    with patch("api.routes.auth.verify_apple_identity_token", new_callable=AsyncMock) as mock_verify, \
         patch("api.routes.auth.UserRepository") as MockRepo:
        mock_verify.return_value = {"sub": "apple123", "email": "runner@test.com"}
        mock_instance = MockRepo.return_value
        mock_instance.find_by_apple_id = AsyncMock(return_value=None)
        mock_instance.create = AsyncMock(return_value="user_db_id")

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            resp = await ac.post("/api/auth/apple", json={
                "identity_token": "fake.token.here",
                "display_name": "Test Runner"
            })
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert "refresh_token" in data
```

**Step 2: Write api/routes/auth.py**

```python
# api/routes/auth.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from utils.apple_auth import verify_apple_identity_token
from utils.jwt_utils import create_access_token, create_refresh_token, decode_token
from db.repositories.user_repo import UserRepository
from db.models import UserDB
from config.settings import get_settings

router = APIRouter()


class AppleAuthRequest(BaseModel):
    identity_token: str
    display_name: Optional[str] = None


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str
    onboarding_complete: bool


class RefreshRequest(BaseModel):
    refresh_token: str


@router.post("/apple", response_model=AuthResponse)
async def apple_auth(body: AppleAuthRequest):
    settings = get_settings()
    try:
        claims = await verify_apple_identity_token(
            body.identity_token, settings.APPLE_APP_BUNDLE_ID
        )
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Apple token: {e}")

    apple_user_id = claims["sub"]
    email = claims.get("email", "")
    repo = UserRepository()
    user = await repo.find_by_apple_id(apple_user_id)

    if user is None:
        new_user = UserDB(
            email=email,
            display_name=body.display_name or email.split("@")[0],
            apple_user_id=apple_user_id,
        )
        user_id = await repo.create(new_user)
        onboarding_complete = False
    else:
        user_id = str(user.id)
        onboarding_complete = user.onboarding_complete

    return AuthResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
        user_id=user_id,
        onboarding_complete=onboarding_complete,
    )


@router.post("/refresh")
async def refresh_token(body: RefreshRequest):
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise ValueError("Not a refresh token")
        user_id = payload["sub"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    return {
        "access_token": create_access_token(user_id),
        "refresh_token": create_refresh_token(user_id),
    }
```

**Step 3: Run tests**

```bash
pytest tests/api/test_auth_routes.py -v
```
Expected: PASS

**Step 4: Commit**

```bash
git add api/routes/auth.py tests/api/test_auth_routes.py
git commit -m "feat: add Apple Sign-In auth route with JWT issuance"
```

---

### Task 13: Users, Plans, Workouts, Runs routes

**Files:**
- Create: `pacepilot-server/api/routes/users.py`
- Create: `pacepilot-server/api/routes/plans.py`
- Create: `pacepilot-server/api/routes/workouts.py`
- Create: `pacepilot-server/api/routes/runs.py`

```python
# api/routes/users.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository

router = APIRouter()


class UserUpdateRequest(BaseModel):
    display_name: Optional[str] = None
    weekly_mileage_goal: Optional[float] = None
    target_race_distance: Optional[str] = None
    resting_hr: Optional[int] = None
    max_hr: Optional[int] = None
    preferred_days: Optional[list[int]] = None
    onboarding_complete: Optional[bool] = None


@router.get("/me")
async def get_me(user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user.model_dump(by_alias=False)


@router.patch("/me")
async def update_me(body: UserUpdateRequest, user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    updates = body.model_dump(exclude_none=True)
    await repo.update(user_id, updates)
    return {"ok": True}


@router.get("/me/stats")
async def get_stats(user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    return await repo.get_stats(user_id)
```

```python
# api/routes/plans.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from api.middleware.auth import get_current_user_id
from db.repositories.plan_repo import PlanRepository
from db.repositories.workout_repo import WorkoutRepository
from db.repositories.user_repo import UserRepository
from db.models import TrainingPlanDB
from services.pace_calculator import PaceCalculator
from services.plan_engine import PlanEngine

router = APIRouter()


class GeneratePlanRequest(BaseModel):
    benchmark_distance_km: float = 5.0
    benchmark_time_seconds: float = 1500.0
    weeks: int = 12
    preferred_days: list[int] = [0, 2, 4, 6]


@router.post("/generate")
async def generate_plan(body: GeneratePlanRequest, user_id: str = Depends(get_current_user_id)):
    calc = PaceCalculator()
    vdot = calc.vdot_from_race(body.benchmark_distance_km, body.benchmark_time_seconds)
    pace_zones = calc.pace_zones_from_vdot(vdot)

    user_repo = UserRepository()
    user = await user_repo.find_by_id(user_id)
    hr_zones = None
    if user and user.resting_hr and user.max_hr:
        hr_zones = calc.hr_zones(user.resting_hr, user.max_hr)

    plan_repo = PlanRepository()
    await plan_repo.deactivate_all(user_id)

    start = datetime.utcnow()
    from datetime import timedelta
    plan = TrainingPlanDB(
        user_id=user_id,
        start_date=start,
        end_date=start + timedelta(weeks=body.weeks),
        pace_zones=pace_zones,
        hr_zones=hr_zones,
    )
    plan_id = await plan_repo.create(plan)

    engine = PlanEngine()
    workouts = engine.generate_workouts(
        user_id=user_id,
        plan_id=plan_id,
        start_date=start,
        weeks=body.weeks,
        preferred_days=body.preferred_days,
        pace_zones=pace_zones,
    )
    workout_repo = WorkoutRepository()
    await workout_repo.create_many(workouts)

    return {"plan_id": plan_id, "workout_count": len(workouts)}


@router.get("/active")
async def get_active_plan(user_id: str = Depends(get_current_user_id)):
    repo = PlanRepository()
    plan = await repo.get_active(user_id)
    if not plan:
        raise HTTPException(status_code=404, detail="No active plan")
    return plan.model_dump(by_alias=False)


@router.get("/{plan_id}/workouts")
async def get_plan_workouts(plan_id: str, user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    return [w.model_dump(by_alias=False) for w in await repo.get_by_plan(plan_id)]


@router.patch("/{plan_id}")
async def update_plan(plan_id: str, body: dict, user_id: str = Depends(get_current_user_id)):
    repo = PlanRepository()
    await repo.update(plan_id, body)
    return {"ok": True}
```

```python
# api/routes/workouts.py
from fastapi import APIRouter, Depends, HTTPException
from api.middleware.auth import get_current_user_id
from db.repositories.workout_repo import WorkoutRepository
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

router = APIRouter()


class RescheduleRequest(BaseModel):
    new_date: datetime


@router.get("/today")
async def get_today(user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    workout = await repo.get_today(user_id)
    if not workout:
        raise HTTPException(status_code=404, detail="No workout today")
    return workout.model_dump(by_alias=False)


@router.get("/week")
async def get_week(user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    return [w.model_dump(by_alias=False) for w in await repo.get_week(user_id)]


@router.patch("/{workout_id}/reschedule")
async def reschedule(workout_id: str, body: RescheduleRequest, user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    await repo.update(workout_id, {"scheduled_date": body.new_date})
    return {"ok": True}


@router.patch("/{workout_id}/skip")
async def skip(workout_id: str, user_id: str = Depends(get_current_user_id)):
    repo = WorkoutRepository()
    await repo.update(workout_id, {"is_skipped": True})
    return {"ok": True}
```

```python
# api/routes/runs.py
from fastapi import APIRouter, Depends, HTTPException, Query
from api.middleware.auth import get_current_user_id
from db.repositories.run_repo import RunRepository
from db.models import RunSessionDB
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

router = APIRouter()


class NewRunRequest(BaseModel):
    workout_id: Optional[str] = None
    started_at: datetime
    ended_at: datetime
    distance_km: float
    duration_seconds: int
    avg_pace_seconds_per_km: float
    avg_heart_rate: int
    max_heart_rate: int
    calories: int
    elevation_gain_meters: float = 0.0
    splits: list = []
    gps_track: list = []


@router.post("")
async def save_run(body: NewRunRequest, user_id: str = Depends(get_current_user_id)):
    repo = RunRepository()
    run = RunSessionDB(
        user_id=user_id,
        **body.model_dump()
    )
    run_id = await repo.create(run)
    return {"id": run_id}


@router.get("")
async def list_runs(
    user_id: str = Depends(get_current_user_id),
    limit: int = Query(20, le=100),
    skip: int = 0,
):
    repo = RunRepository()
    runs = await repo.list_for_user(user_id, limit=limit, skip=skip)
    return [r.model_dump(by_alias=False) for r in runs]


@router.get("/recent")
async def recent_runs(count: int = Query(5, le=20), user_id: str = Depends(get_current_user_id)):
    repo = RunRepository()
    runs = await repo.get_recent(user_id, count=count)
    return [r.model_dump(by_alias=False) for r in runs]


@router.get("/{run_id}")
async def get_run(run_id: str, user_id: str = Depends(get_current_user_id)):
    repo = RunRepository()
    run = await repo.get_by_id(run_id)
    if not run or run.user_id != user_id:
        raise HTTPException(status_code=404, detail="Run not found")
    return run.model_dump(by_alias=False)
```

**Step 2: Commit**

```bash
git add api/routes/users.py api/routes/plans.py api/routes/workouts.py api/routes/runs.py
git commit -m "feat: add users, plans, workouts, and runs API routes"
```

---

### Task 14: Communities, Races, Calendar, Strava routes

**Files:**
- Create: `pacepilot-server/api/routes/communities.py`
- Create: `pacepilot-server/api/routes/races.py`
- Create: `pacepilot-server/api/routes/calendar.py`
- Create: `pacepilot-server/api/routes/strava.py`

```python
# api/routes/communities.py
from fastapi import APIRouter, Depends
from api.middleware.auth import get_current_user_id
from db.repositories.community_repo import CommunityRepository
from services.community_service import CommunityService

router = APIRouter()


@router.get("/me")
async def get_my_community(user_id: str = Depends(get_current_user_id)):
    svc = CommunityService()
    tier = await svc.compute_tier(user_id)
    repo = CommunityRepository()
    community = await repo.get_by_tier(tier)
    return {
        "tier": tier,
        "community": community.model_dump(by_alias=False) if community else None,
    }


@router.get("/me/leaderboard")
async def get_leaderboard(user_id: str = Depends(get_current_user_id)):
    svc = CommunityService()
    tier = await svc.compute_tier(user_id)
    repo = CommunityRepository()
    community = await repo.get_by_tier(tier)
    if not community:
        return []
    return await repo.get_leaderboard(str(community.id))


@router.get("/friends/activity")
async def get_friend_activity(user_id: str = Depends(get_current_user_id)):
    repo = CommunityRepository()
    return await repo.get_friend_activity(user_id)
```

```python
# api/routes/races.py
from fastapi import APIRouter, Depends, Query
from typing import Optional
from api.middleware.auth import get_current_user_id
from services.race_service import RaceService

router = APIRouter()


@router.get("/discover")
async def discover_races(
    distance_km: Optional[float] = Query(None),
    user_id: str = Depends(get_current_user_id),
):
    svc = RaceService()
    races = await svc.discover(distance_km=distance_km)
    return [
        {**r.model_dump(by_alias=False), "is_interested_by_user": user_id in r.interested_user_ids}
        for r in races
    ]


@router.get("/{race_id}")
async def get_race(race_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RaceService()
    race = await svc.get(race_id)
    return race.model_dump(by_alias=False) if race else {}


@router.post("/{race_id}/register-interest")
async def register_interest(race_id: str, user_id: str = Depends(get_current_user_id)):
    svc = RaceService()
    await svc.register_interest(race_id, user_id)
    return {"ok": True}
```

```python
# api/routes/calendar.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository
from services.calendar_service import CalendarService

router = APIRouter()


class SyncRequest(BaseModel):
    workout_ids: list[str]


@router.post("/sync")
async def sync_to_calendar(body: SyncRequest, user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    user = await repo.find_by_id(user_id)
    if not user or not user.google_calendar_token:
        raise HTTPException(status_code=400, detail="Google Calendar not connected")
    from db.repositories.workout_repo import WorkoutRepository
    workout_repo = WorkoutRepository()
    svc = CalendarService()
    for wid in body.workout_ids:
        workout = await workout_repo.get_by_id(wid)
        if workout:
            await svc.create_event(
                user.google_calendar_token,
                {
                    "scheduled_date": workout.scheduled_date.isoformat(),
                    "type": workout.type,
                    "target_distance_km": workout.target_distance_km,
                    "target_pace_zone": workout.target_pace_zone,
                }
            )
    return {"synced": len(body.workout_ids)}
```

```python
# api/routes/strava.py
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import RedirectResponse
from api.middleware.auth import get_current_user_id
from db.repositories.user_repo import UserRepository
from services.strava_service import StravaService

router = APIRouter()


@router.get("/auth-url")
async def get_auth_url(user_id: str = Depends(get_current_user_id)):
    svc = StravaService()
    return {"auth_url": svc.get_auth_url()}


@router.get("/callback")
async def strava_callback(code: str = Query(...), state: str = Query(None)):
    svc = StravaService()
    token_data = await svc.exchange_code(code)
    # In production, use state param to retrieve user_id from session
    # For now, return token data (frontend stores it)
    return {"strava_data": token_data}


@router.post("/sync")
async def manual_sync(user_id: str = Depends(get_current_user_id)):
    return {"ok": True, "message": "Strava sync triggered"}


@router.delete("/disconnect")
async def disconnect_strava(user_id: str = Depends(get_current_user_id)):
    repo = UserRepository()
    await repo.update(user_id, {
        "strava_connected": False,
        "strava_access_token": None,
        "strava_refresh_token": None,
    })
    return {"ok": True}
```

**Step 2: Commit**

```bash
git add api/routes/communities.py api/routes/races.py api/routes/calendar.py api/routes/strava.py
git commit -m "feat: add communities, races, calendar, and strava API routes"
```

---

## Phase 5: Voice Pipeline

### Task 15: Biometric store + RunContextProcessor

**Files:**
- Create: `pacepilot-server/voice/context/biometric_store.py`
- Create: `pacepilot-server/voice/context/run_context_processor.py`

```python
# voice/context/biometric_store.py
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional
import asyncio

@dataclass
class BiometricSnapshot:
    heart_rate: float = 0.0
    pace_seconds_per_km: float = 0.0
    distance_km: float = 0.0
    elapsed_seconds: int = 0
    updated_at: datetime = field(default_factory=datetime.utcnow)


class BiometricStore:
    """Thread-safe in-memory store of live biometrics keyed by session_id."""
    _lock = asyncio.Lock()
    _data: dict[str, BiometricSnapshot] = {}

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
```

```python
# voice/context/run_context_processor.py
from pipecat.processors.frame_processor import FrameProcessor
from pipecat.frames.frames import Frame, FunctionCallResultFrame
from voice.context.biometric_store import BiometricStore
from utils.formatters import format_pace, format_duration


class RunContextProcessor(FrameProcessor):
    """Intercepts tool call requests and injects live biometric context."""

    def __init__(self, session_id: str):
        super().__init__()
        self.session_id = session_id

    async def process_frame(self, frame: Frame, direction):
        # Pass all frames through; tool handlers are wired separately
        await self.push_frame(frame, direction)
```

**Step 2: Commit**

```bash
git add voice/context/
git commit -m "feat: add BiometricStore and RunContextProcessor for live data injection"
```

---

### Task 16: System Prompts

**Files:**
- Create: `pacepilot-server/voice/system_prompts/onboarding.py`
- Create: `pacepilot-server/voice/system_prompts/active_run.py`
- Create: `pacepilot-server/voice/system_prompts/post_run.py`
- Create: `pacepilot-server/voice/system_prompts/general.py`

```python
# voice/system_prompts/onboarding.py
ONBOARDING_PROMPT = """You are PacePilot, an AI running coach. This is a new runner's first conversation with you.

Your goal is to learn about them through friendly, conversational voice dialogue — NOT forms. Collect the following through natural conversation:

1. Their name and running experience (beginner / intermediate / advanced)
2. Their primary goal (finish a race, get faster, lose weight, stay healthy)
3. Target race: distance and date (if any)
4. How many days per week they can run and which days
5. A recent race time or estimated 5K time for pace zone calculation
6. Resting heart rate (ask them to check Apple Watch or just estimate)
7. Any injuries or health concerns
8. Whether they want to connect Strava or Google Calendar

As you collect each piece of information, IMMEDIATELY call update_user_profile to save it.
When you have enough to build a plan (at minimum: goal, preferred days, and a pace estimate), call generate_training_plan.

Rules:
- One question at a time. Don't overwhelm them.
- Be warm, encouraging, and excited for their journey.
- If they seem impatient, move faster and ask fewer questions.
- End with: tell them their plan is ready and what their first workout is.
"""
```

```python
# voice/system_prompts/active_run.py
ACTIVE_RUN_PROMPT = """You are PacePilot, an AI running coach riding alongside the runner RIGHT NOW.

You have live access to their biometrics through tools. ALWAYS use tools — never guess pace, HR, or distance.

## Coaching Modes

**Active Coaching** (intervals, tempo, race pace runs):
- Speak every 30–60 seconds
- Call get_current_biometrics and get_run_progress on every check-in
- Give specific feedback: "Your pace is 4:45, right on target for this tempo segment."
- Warn if HR is >90% of max: "Heart rate is high — ease off slightly."

**Companion Mode** (easy, recovery, warm-up):
- Check in every 3–5 minutes
- Conversational tone: "How are you feeling? Pace looks easy and comfortable."
- Ask about their day, race goals, how they slept

**Silent Mode** (if user says "quiet" or "silence"):
- Only speak for: km milestones, pace alerts (>15% off target), HR alerts, interval transitions

## Rules
- Never invent numbers. All pace/HR/distance claims must come from a tool call.
- Compare to their history when motivating: call get_recent_runs for context.
- Celebrate milestones (5km, 10km, halfway, personal bests).
- If asked a question mid-run, answer briefly then return to coaching.
- If they sound distressed, ask if they need to stop.
- Do NOT say "as an AI" or break the coaching persona.
"""
```

```python
# voice/system_prompts/post_run.py
POST_RUN_PROMPT = """You are PacePilot delivering a post-run debrief.

1. Start by congratulating them on finishing.
2. Call get_run_progress to get final stats, then narrate them naturally:
   "You covered 8.4 kilometres in 42 minutes — that's a 5:00 per kilometre average. Solid work."
3. Compare to recent runs: call get_recent_runs and highlight improvements.
4. Note anything worthy: new distance PR, consistent pace, strong finish.
5. Preview the next workout: call get_todays_workout (or get_plan_status for next session).
6. End with genuine encouragement. Keep it under 90 seconds total.

Rules:
- Be specific — use real numbers from tool calls.
- Don't pad with filler. Runners are tired; get to the point.
- Positive but honest: if they blew up, acknowledge it and explain why it's normal.
"""
```

```python
# voice/system_prompts/general.py
GENERAL_PROMPT = """You are PacePilot, an AI running coach. The runner is not currently on a run.

Answer questions about:
- Their training plan (call get_plan_status, get_todays_workout)
- Their recent performance (call get_recent_runs, get_personal_records)
- Race strategy (call find_local_races)
- Schedule changes (call reschedule_workout)
- Their community standing (call get_leaderboard_position, get_friend_activity)

Rules:
- Always use tools to get real data — don't make up statistics.
- Be concise. Voice responses should be under 30 seconds for simple questions.
- If they want to reschedule a workout, confirm the new date before calling the tool.
"""

SESSION_TYPE_PROMPTS = {
    "onboarding": __import__("voice.system_prompts.onboarding", fromlist=["ONBOARDING_PROMPT"]).ONBOARDING_PROMPT,
    "active_run": ACTIVE_RUN_PROMPT,
    "post_run": POST_RUN_PROMPT,
    "general": GENERAL_PROMPT,
    "pre_run": GENERAL_PROMPT,
}
```

**Step 2: Commit**

```bash
git add voice/system_prompts/
git commit -m "feat: add system prompts for onboarding, active run, post run, and general sessions"
```

---

### Task 17: Voice Tool Definitions + Biometric/Plan Tools

**Files:**
- Create: `pacepilot-server/voice/tools/definitions.py`
- Create: `pacepilot-server/voice/tools/biometric_tools.py`
- Create: `pacepilot-server/voice/tools/plan_tools.py`

```python
# voice/tools/definitions.py
"""All 16 Gemini Live tool function declarations."""

PACEPILOT_TOOLS = [
    {
        "name": "get_current_biometrics",
        "description": "Returns the runner's real-time heart rate, pace, distance, and cadence RIGHT NOW.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_run_progress",
        "description": "Returns current run distance, elapsed time, and split paces.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_todays_workout",
        "description": "Returns today's scheduled workout details including type, distance, and target pace zone.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_recent_runs",
        "description": "Returns the last N completed runs with distance, pace, and HR.",
        "parameters": {
            "type": "object",
            "properties": {"count": {"type": "integer", "description": "Number of recent runs (default 5)"}},
            "required": [],
        },
    },
    {
        "name": "get_personal_records",
        "description": "Returns the user's personal best paces for 5K, 10K, half marathon, and marathon.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_weekly_stats",
        "description": "Returns total distance and number of runs this week.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_plan_status",
        "description": "Returns the current training plan phase, week number, and completion percentage.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_friend_activity",
        "description": "Returns recent runs from other runners in the user's community tier.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_leaderboard_position",
        "description": "Returns the user's rank on the weekly distance leaderboard in their community.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "find_local_races",
        "description": "Finds upcoming races filtered by distance.",
        "parameters": {
            "type": "object",
            "properties": {"distance_km": {"type": "number", "description": "Target race distance in km (e.g., 5, 10, 21.1, 42.2)"}},
            "required": [],
        },
    },
    {
        "name": "schedule_run_to_calendar",
        "description": "Adds a workout to the user's Google Calendar.",
        "parameters": {
            "type": "object",
            "properties": {"workout_id": {"type": "string", "description": "The workout ID to schedule"}},
            "required": ["workout_id"],
        },
    },
    {
        "name": "reschedule_workout",
        "description": "Moves a workout to a different date.",
        "parameters": {
            "type": "object",
            "properties": {
                "workout_id": {"type": "string"},
                "new_date": {"type": "string", "description": "ISO 8601 date string"},
            },
            "required": ["workout_id", "new_date"],
        },
    },
    {
        "name": "update_user_profile",
        "description": "Updates the user's profile during onboarding (name, goals, pace, preferred days, etc.).",
        "parameters": {
            "type": "object",
            "properties": {
                "display_name": {"type": "string"},
                "weekly_mileage_goal": {"type": "number"},
                "target_race_distance": {"type": "string"},
                "resting_hr": {"type": "integer"},
                "max_hr": {"type": "integer"},
                "preferred_days": {"type": "array", "items": {"type": "integer"}},
                "onboarding_complete": {"type": "boolean"},
            },
            "required": [],
        },
    },
    {
        "name": "generate_training_plan",
        "description": "Generates a personalised training plan based on user's goals and fitness level.",
        "parameters": {
            "type": "object",
            "properties": {
                "benchmark_distance_km": {"type": "number", "description": "Race distance used for VDOT calculation"},
                "benchmark_time_seconds": {"type": "number", "description": "Race time in seconds"},
                "weeks": {"type": "integer", "description": "Plan duration in weeks (default 12)"},
                "preferred_days": {"type": "array", "items": {"type": "integer"}},
            },
            "required": [],
        },
    },
    {
        "name": "mark_not_feeling_well",
        "description": "Converts today's workout to an easy recovery run when the runner feels unwell.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
]
```

```python
# voice/tools/biometric_tools.py
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
```

```python
# voice/tools/plan_tools.py
from datetime import datetime
from db.repositories.plan_repo import PlanRepository
from db.repositories.workout_repo import WorkoutRepository
from services.pace_calculator import PaceCalculator
from services.plan_engine import PlanEngine
from db.models import TrainingPlanDB


async def get_todays_workout(user_id: str, **kwargs) -> dict:
    repo = WorkoutRepository()
    workout = await repo.get_today(user_id)
    if not workout:
        return {"message": "No workout scheduled today — it's a rest day!"}
    return {
        "type": workout.type,
        "distance_km": workout.target_distance_km,
        "pace_zone": workout.target_pace_zone,
        "segments": [s.model_dump() for s in workout.segments],
    }


async def get_plan_status(user_id: str, **kwargs) -> dict:
    repo = PlanRepository()
    plan = await repo.get_active(user_id)
    if not plan:
        return {"message": "No active training plan"}
    now = datetime.utcnow()
    total_days = (plan.end_date - plan.start_date).days
    elapsed_days = (now - plan.start_date).days
    week_number = elapsed_days // 7 + 1
    return {
        "phase": plan.phase,
        "week_number": week_number,
        "total_weeks": total_days // 7,
        "percent_complete": round(elapsed_days / total_days * 100, 1),
    }


async def generate_training_plan(
    user_id: str,
    benchmark_distance_km: float = 5.0,
    benchmark_time_seconds: float = 1500.0,
    weeks: int = 12,
    preferred_days: list = None,
    **kwargs
) -> dict:
    if preferred_days is None:
        preferred_days = [0, 2, 4, 6]

    calc = PaceCalculator()
    vdot = calc.vdot_from_race(benchmark_distance_km, benchmark_time_seconds)
    pace_zones = calc.pace_zones_from_vdot(vdot)

    plan_repo = PlanRepository()
    await plan_repo.deactivate_all(user_id)

    from datetime import timedelta
    start = datetime.utcnow()
    plan = TrainingPlanDB(
        user_id=user_id,
        start_date=start,
        end_date=start + timedelta(weeks=weeks),
        pace_zones=pace_zones,
    )
    plan_id = await plan_repo.create(plan)

    engine = PlanEngine()
    workouts = engine.generate_workouts(
        user_id=user_id, plan_id=plan_id, start_date=start,
        weeks=weeks, preferred_days=preferred_days, pace_zones=pace_zones,
    )
    workout_repo = WorkoutRepository()
    await workout_repo.create_many(workouts)

    return {
        "plan_id": plan_id,
        "workout_count": len(workouts),
        "easy_pace": f"{pace_zones.easy // 60}:{pace_zones.easy % 60:02d}/km",
        "first_workout_type": workouts[0].type if workouts else "easy",
    }


async def reschedule_workout(user_id: str, workout_id: str, new_date: str, **kwargs) -> dict:
    from datetime import datetime
    repo = WorkoutRepository()
    await repo.update(workout_id, {"scheduled_date": datetime.fromisoformat(new_date)})
    return {"ok": True, "message": f"Workout rescheduled to {new_date}"}
```

**Step 2: Commit**

```bash
git add voice/tools/definitions.py voice/tools/biometric_tools.py voice/tools/plan_tools.py
git commit -m "feat: add 16 Gemini tool definitions and biometric/plan tool handlers"
```

---

### Task 18: History, Social, Calendar, Race, User Tools

**Files:**
- Create: `pacepilot-server/voice/tools/history_tools.py`
- Create: `pacepilot-server/voice/tools/social_tools.py`
- Create: `pacepilot-server/voice/tools/calendar_tools.py`
- Create: `pacepilot-server/voice/tools/race_tools.py`
- Create: `pacepilot-server/voice/tools/user_tools.py`

```python
# voice/tools/history_tools.py
from db.repositories.run_repo import RunRepository
from db.repositories.user_repo import UserRepository
from utils.formatters import format_pace


async def get_recent_runs(user_id: str, count: int = 5, **kwargs) -> list:
    repo = RunRepository()
    runs = await repo.get_recent(user_id, count=count)
    return [
        {
            "date": r.started_at.strftime("%A, %b %d"),
            "distance_km": round(r.distance_km, 2),
            "avg_pace": format_pace(r.avg_pace_seconds_per_km),
            "avg_hr": r.avg_heart_rate,
        }
        for r in runs
    ]


async def get_personal_records(user_id: str, **kwargs) -> dict:
    repo = RunRepository()
    prs = await repo.get_personal_records(user_id)
    return {dist: format_pace(pace) for dist, pace in prs.items()}


async def get_weekly_stats(user_id: str, **kwargs) -> dict:
    repo = UserRepository()
    return await repo.get_stats(user_id)
```

```python
# voice/tools/social_tools.py
from db.repositories.community_repo import CommunityRepository
from services.community_service import CommunityService
from utils.formatters import format_pace


async def get_friend_activity(user_id: str, **kwargs) -> list:
    repo = CommunityRepository()
    activities = await repo.get_friend_activity(user_id, limit=5)
    return [
        {
            "name": a["display_name"],
            "distance_km": round(a["distance_km"], 2),
            "pace": format_pace(a["pace_seconds_per_km"]),
        }
        for a in activities
    ]


async def get_leaderboard_position(user_id: str, **kwargs) -> dict:
    svc = CommunityService()
    tier = await svc.compute_tier(user_id)
    repo = CommunityRepository()
    community = await repo.get_by_tier(tier)
    if not community:
        return {"tier": tier, "rank": None}
    leaderboard = await repo.get_leaderboard(str(community.id))
    my_entry = next((e for e in leaderboard if e["user_id"] == user_id), None)
    return {
        "tier": tier,
        "rank": my_entry["rank"] if my_entry else "unranked",
        "weekly_distance_km": round(my_entry["weekly_distance_km"], 2) if my_entry else 0,
        "total_in_tier": len(leaderboard),
    }
```

```python
# voice/tools/calendar_tools.py
from db.repositories.workout_repo import WorkoutRepository
from db.repositories.user_repo import UserRepository
from services.calendar_service import CalendarService


async def schedule_run_to_calendar(user_id: str, workout_id: str, **kwargs) -> dict:
    user_repo = UserRepository()
    user = await user_repo.find_by_id(user_id)
    if not user or not user.google_calendar_token:
        return {"error": "Google Calendar not connected. Ask the user to connect it in Profile settings."}
    workout_repo = WorkoutRepository()
    workout = await workout_repo.get_by_id(workout_id)
    if not workout:
        return {"error": "Workout not found"}
    svc = CalendarService()
    await svc.create_event(user.google_calendar_token, {
        "scheduled_date": workout.scheduled_date.isoformat(),
        "type": workout.type,
        "target_distance_km": workout.target_distance_km,
        "target_pace_zone": workout.target_pace_zone,
    })
    return {"ok": True, "message": f"Added {workout.type} run on {workout.scheduled_date.strftime('%A')} to your calendar."}
```

```python
# voice/tools/race_tools.py
from services.race_service import RaceService


async def find_local_races(user_id: str, distance_km: float = None, **kwargs) -> list:
    svc = RaceService()
    races = await svc.discover(distance_km=distance_km)
    return [
        {
            "name": r.name,
            "distance_km": r.distance_km,
            "date": r.date.strftime("%B %d, %Y"),
            "location": r.location,
        }
        for r in races[:5]
    ]
```

```python
# voice/tools/user_tools.py
from db.repositories.user_repo import UserRepository
from db.repositories.workout_repo import WorkoutRepository


async def update_user_profile(user_id: str, **kwargs) -> dict:
    allowed = {
        "display_name", "weekly_mileage_goal", "target_race_distance",
        "resting_hr", "max_hr", "preferred_days", "onboarding_complete",
    }
    updates = {k: v for k, v in kwargs.items() if k in allowed and v is not None}
    if not updates:
        return {"ok": True, "message": "No changes to save"}
    repo = UserRepository()
    await repo.update(user_id, updates)
    return {"ok": True, "updated_fields": list(updates.keys())}


async def mark_not_feeling_well(user_id: str, **kwargs) -> dict:
    repo = WorkoutRepository()
    workout = await repo.get_today(user_id)
    if not workout:
        return {"message": "No workout today — you're already on a rest day."}
    await repo.update(str(workout.id), {
        "type": "recovery",
        "target_distance_km": min(workout.target_distance_km, 4.0),
        "target_pace_zone": "easy",
    })
    return {
        "ok": True,
        "message": "Converted today's workout to an easy 4km recovery run. Listen to your body.",
    }
```

**Step 2: Commit**

```bash
git add voice/tools/
git commit -m "feat: add all 16 voice tool handlers (history, social, calendar, race, user)"
```

---

### Task 19: Session Manager + Pipecat Pipeline

**Files:**
- Create: `pacepilot-server/voice/session_manager.py`
- Create: `pacepilot-server/voice/pipeline.py`

```python
# voice/session_manager.py
import asyncio
import httpx
from datetime import datetime
from typing import Optional
from config.settings import get_settings
from db.repositories.agent_session_repo import AgentSessionRepository
from db.models import AgentSessionDB
from voice.context.biometric_store import BiometricStore, BiometricSnapshot

# Map session_id → asyncio.Task (running pipeline)
_active_pipelines: dict[str, asyncio.Task] = {}
# Map session_id → transcript accumulator
_transcripts: dict[str, list] = {}


async def create_daily_room() -> tuple[str, str]:
    """Create a Daily room and return (room_url, owner_token)."""
    settings = get_settings()
    async with httpx.AsyncClient() as client:
        # Create room
        room_resp = await client.post(
            "https://api.daily.co/v1/rooms",
            headers={"Authorization": f"Bearer {settings.DAILY_API_KEY}"},
            json={"properties": {"exp": int(datetime.utcnow().timestamp()) + 3600}},
        )
        room_resp.raise_for_status()
        room_data = room_resp.json()
        room_url = room_data["url"]
        room_name = room_data["name"]

        # Create owner token for the bot
        token_resp = await client.post(
            "https://api.daily.co/v1/meeting-tokens",
            headers={"Authorization": f"Bearer {settings.DAILY_API_KEY}"},
            json={"properties": {"room_name": room_name, "is_owner": True}},
        )
        token_resp.raise_for_status()
        token = token_resp.json()["token"]

    return room_url, token


async def start_session(user_id: str, session_type: str) -> dict:
    """Create Daily room, persist agent session, start pipeline task."""
    room_url, bot_token = await create_daily_room()

    # Create participant token for the iOS app (non-owner)
    settings = get_settings()
    room_name = room_url.split("/")[-1]
    async with httpx.AsyncClient() as client:
        token_resp = await client.post(
            "https://api.daily.co/v1/meeting-tokens",
            headers={"Authorization": f"Bearer {settings.DAILY_API_KEY}"},
            json={"properties": {"room_name": room_name}},
        )
        token_resp.raise_for_status()
        client_token = token_resp.json()["token"]

    # Persist session
    repo = AgentSessionRepository()
    session = AgentSessionDB(
        user_id=user_id,
        session_type=session_type,
        daily_room_url=room_url,
    )
    session_id = await repo.create(session)

    # Launch pipeline in background
    from voice.pipeline import run_pipeline
    task = asyncio.create_task(
        run_pipeline(session_id=session_id, user_id=user_id,
                     session_type=session_type, room_url=room_url, bot_token=bot_token)
    )
    _active_pipelines[session_id] = task
    _transcripts[session_id] = []

    return {"session_id": session_id, "room_url": room_url, "token": client_token}


async def update_biometrics(session_id: str, heart_rate: float,
                             pace_seconds_per_km: float, distance_km: float,
                             elapsed_seconds: int) -> None:
    await BiometricStore.update(session_id, BiometricSnapshot(
        heart_rate=heart_rate,
        pace_seconds_per_km=pace_seconds_per_km,
        distance_km=distance_km,
        elapsed_seconds=elapsed_seconds,
    ))


async def end_session(session_id: str) -> dict:
    """Stop pipeline, save transcript, clean up."""
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
```

```python
# voice/pipeline.py
import asyncio
from config.settings import get_settings
from voice.system_prompts.general import SESSION_TYPE_PROMPTS
from voice.tools.definitions import PACEPILOT_TOOLS

# Tool handler registry
from voice.tools import biometric_tools, plan_tools, history_tools, social_tools
from voice.tools import calendar_tools, race_tools, user_tools

TOOL_HANDLERS = {
    "get_current_biometrics": biometric_tools.get_current_biometrics,
    "get_run_progress": biometric_tools.get_run_progress,
    "get_todays_workout": plan_tools.get_todays_workout,
    "get_plan_status": plan_tools.get_plan_status,
    "generate_training_plan": plan_tools.generate_training_plan,
    "reschedule_workout": plan_tools.reschedule_workout,
    "get_recent_runs": history_tools.get_recent_runs,
    "get_personal_records": history_tools.get_personal_records,
    "get_weekly_stats": history_tools.get_weekly_stats,
    "get_friend_activity": social_tools.get_friend_activity,
    "get_leaderboard_position": social_tools.get_leaderboard_position,
    "schedule_run_to_calendar": calendar_tools.schedule_run_to_calendar,
    "find_local_races": race_tools.find_local_races,
    "update_user_profile": user_tools.update_user_profile,
    "mark_not_feeling_well": user_tools.mark_not_feeling_well,
}


async def run_pipeline(session_id: str, user_id: str, session_type: str,
                       room_url: str, bot_token: str) -> None:
    """Run the Pipecat pipeline for a voice session."""
    try:
        from pipecat.pipeline.pipeline import Pipeline
        from pipecat.pipeline.runner import PipelineRunner
        from pipecat.pipeline.task import PipelineTask
        from pipecat.transports.services.daily import DailyParams, DailyTransport
        from pipecat.services.google import GeminiLiveLLMService, InputParams
        from pipecat.frames.frames import LLMFullResponseEndFrame

        settings = get_settings()
        system_prompt = SESSION_TYPE_PROMPTS.get(session_type, SESSION_TYPE_PROMPTS["general"])

        transport = DailyTransport(
            room_url,
            bot_token,
            "PacePilot Coach",
            DailyParams(audio_out_enabled=True, audio_in_enabled=True),
        )

        llm = GeminiLiveLLMService(
            api_key=settings.GCP_PROJECT_ID,   # Vertex AI uses project, not key
            model="models/gemini-2.5-flash-native-audio-preview-12-2025",
            voice_id="Charon",
            system_instruction=system_prompt,
            tools=PACEPILOT_TOOLS,
            params=InputParams(enable_automatic_punctuation=True),
        )

        # Wire tool call handling
        @llm.event_handler("on_function_call")
        async def handle_tool_call(name: str, arguments: dict):
            handler = TOOL_HANDLERS.get(name)
            if handler:
                result = await handler(user_id=user_id, session_id=session_id, **arguments)
                await llm.push_function_result(name, result)
            else:
                await llm.push_function_result(name, {"error": f"Unknown tool: {name}"})

        pipeline = Pipeline([transport.input(), llm, transport.output()])
        task = PipelineTask(pipeline)
        runner = PipelineRunner()
        await runner.run(task)

    except asyncio.CancelledError:
        pass
    except Exception as e:
        print(f"Pipeline error for session {session_id}: {e}")
```

**Step 2: Commit**

```bash
git add voice/session_manager.py voice/pipeline.py
git commit -m "feat: add Pipecat pipeline and session manager with Daily room creation"
```

---

### Task 20: Voice API routes

**Files:**
- Create: `pacepilot-server/api/routes/voice.py`

```python
# api/routes/voice.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from api.middleware.auth import get_current_user_id
from voice import session_manager
from db.repositories.agent_session_repo import AgentSessionRepository

router = APIRouter()


class CreateSessionRequest(BaseModel):
    session_type: str   # onboarding | pre_run | active_run | post_run | general


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
        return await session_manager.start_session(
            user_id=user_id, session_type=body.session_type
        )
    except Exception as e:
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
    result = await session_manager.end_session(body.session_id)
    return result


@router.get("/sessions")
async def list_sessions(user_id: str = Depends(get_current_user_id)):
    repo = AgentSessionRepository()
    sessions = await repo.list_for_user(user_id)
    return [s.model_dump(by_alias=False) for s in sessions]
```

**Step 2: Commit**

```bash
git add api/routes/voice.py
git commit -m "feat: add voice session API routes (create, biometrics, end, history)"
```

---

## Phase 6: Main Entry Point

### Task 21: main.py — wire everything together

**Files:**
- Create: `pacepilot-server/main.py`

```python
# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from db.connection import close_connection
from api.routes import auth, users, plans, workouts, runs, communities, races, calendar, strava, voice


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    yield
    # Shutdown
    await close_connection()


app = FastAPI(title="PacePilot API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Tighten for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,        prefix="/api/auth",        tags=["auth"])
app.include_router(users.router,       prefix="/api/users",       tags=["users"])
app.include_router(plans.router,       prefix="/api/plans",       tags=["plans"])
app.include_router(workouts.router,    prefix="/api/workouts",    tags=["workouts"])
app.include_router(runs.router,        prefix="/api/runs",        tags=["runs"])
app.include_router(communities.router, prefix="/api/communities", tags=["communities"])
app.include_router(races.router,       prefix="/api/races",       tags=["races"])
app.include_router(calendar.router,    prefix="/api/calendar",    tags=["calendar"])
app.include_router(strava.router,      prefix="/api/strava",      tags=["strava"])
app.include_router(voice.router,       prefix="/api/voice",       tags=["voice"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "pacepilot-api"}
```

**Step 2: Verify server starts**

```bash
cd pacepilot-server && cp .env.example .env
# Edit .env with your actual values, then:
uvicorn main:app --reload --port 8000
```
Expected: Server starts, `GET http://localhost:8000/health` returns `{"status": "ok"}`

**Step 3: Run all tests**

```bash
pytest -v
```
Expected: All tests PASS

**Step 4: Final commit**

```bash
git add pacepilot-server/main.py
git commit -m "feat: wire all routes into FastAPI app — pacepilot-server complete"
```

---

## Summary

| Phase | Tasks | What Gets Built |
|-------|-------|----------------|
| 1 | 1–5 | Scaffold, settings, DB models, JWT utils, Apple auth, auth middleware |
| 2 | 6–8 | All 7 MongoDB repositories |
| 3 | 9–11 | PaceCalculator (VDOT), PlanEngine, Community/Strava/Calendar/Race services |
| 4 | 12–14 | All 10 REST API route modules |
| 5 | 15–20 | Biometric store, system prompts, all 16 tool handlers, Pipecat pipeline, session manager, voice routes |
| 6 | 21 | main.py wiring + health check |

**Run server:** `cd pacepilot-server && uvicorn main:app --reload`
**Run tests:** `cd pacepilot-server && pytest -v`
**API docs:** `http://localhost:8000/docs`
