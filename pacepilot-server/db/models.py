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
    preferred_days: List[int] = []
    city: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


class PaceZones(BaseModel):
    easy: float
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


class WorkoutSegment(BaseModel):
    distance_km: float
    pace_zone: str
    description: str


class WorkoutDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    plan_id: str
    user_id: str
    scheduled_date: datetime
    type: str
    target_distance_km: float
    target_pace_zone: str
    segments: List[WorkoutSegment] = []
    is_completed: bool = False
    is_skipped: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


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
    workout_type: Optional[str] = None  # e.g. "easy", "tempo", "interval", "long"
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


class CommunityRunDB(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    name: str
    distance_km: float
    date: datetime
    location: str
    city: str
    latitude: float
    longitude: float
    rsvp_user_ids: List[str] = []

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True


class TranscriptEntry(BaseModel):
    role: str
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
