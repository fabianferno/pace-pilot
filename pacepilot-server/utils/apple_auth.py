import base64
import httpx
from jose import jwt

APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"


async def verify_apple_identity_token(identity_token: str, bundle_id: str) -> dict:
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
    return claims
