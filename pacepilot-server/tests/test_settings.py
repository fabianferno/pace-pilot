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
