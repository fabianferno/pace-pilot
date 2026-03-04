import os

# Set required env vars before any module is imported that calls get_settings()
os.environ.setdefault("MONGODB_URI", "mongodb://localhost:27017")
os.environ.setdefault("JWT_SECRET", "test-secret-key")
os.environ.setdefault("DAILY_API_KEY", "test-daily-key")
os.environ.setdefault("GCP_PROJECT_ID", "test-project")
os.environ.setdefault("APPLE_APP_BUNDLE_ID", "com.test.PacePilot")
