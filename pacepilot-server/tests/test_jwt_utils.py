import pytest
from utils.jwt_utils import create_access_token, decode_token, create_token


def test_roundtrip_access_token():
    token = create_access_token(user_id="abc123", secret="testsecret")
    payload = decode_token(token, secret="testsecret")
    assert payload["sub"] == "abc123"
    assert payload["type"] == "access"


def test_expired_token_raises():
    token = create_token({"sub": "abc"}, secret="s", expire_minutes=-1)
    with pytest.raises(Exception):
        decode_token(token, secret="s")
