from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from db.connection import close_connection
from api.routes import auth, users, plans, workouts, runs, communities, races, calendar, strava, voice


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await close_connection()


app = FastAPI(title="PacePilot API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
