import os
import logging
from typing import Optional
from aioapns import APNs, NotificationRequest, PushType

logger = logging.getLogger(__name__)


class NotificationService:
    _instance: Optional["NotificationService"] = None

    def __init__(self):
        self._client: Optional[APNs] = None

    @classmethod
    def get_instance(cls) -> "NotificationService":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    async def _get_client(self) -> APNs:
        if self._client is None:
            key_path = os.getenv("APNS_KEY_PATH")
            key_id = os.getenv("APNS_KEY_ID")
            team_id = os.getenv("APNS_TEAM_ID")
            topic = os.getenv("APNS_TOPIC", "com.crevn.pacepilot")
            use_sandbox = os.getenv("APP_ENV", "development") == "development"

            if not all([key_path, key_id, team_id]):
                logger.warning("APNs not configured — missing APNS_KEY_PATH, APNS_KEY_ID, or APNS_TEAM_ID")
                raise RuntimeError("APNs not configured")

            self._client = APNs(
                key=key_path,
                key_id=key_id,
                team_id=team_id,
                topic=topic,
                use_sandbox=use_sandbox,
            )
        return self._client

    async def send_push(
        self,
        device_token: str,
        title: str,
        body: str,
        category: str,
        route: Optional[str] = None,
        metadata: Optional[dict] = None,
        badge: Optional[int] = None,
    ) -> bool:
        try:
            client = await self._get_client()
        except RuntimeError:
            logger.warning("Skipping push — APNs not configured")
            return False

        payload = {
            "aps": {
                "alert": {"title": title, "body": body},
                "sound": "default",
                "category": category,
            }
        }
        if badge is not None:
            payload["aps"]["badge"] = badge
        if route:
            payload["route"] = route
        if metadata:
            payload["metadata"] = metadata

        request = NotificationRequest(
            device_token=device_token,
            message=payload,
            push_type=PushType.ALERT,
        )
        response = await client.send_notification(request)
        if not response.is_successful:
            logger.error(f"APNs error for {device_token[:8]}...: {response.description}")
            return False
        return True

    async def send_to_user(
        self,
        user_tokens: list[dict],
        title: str,
        body: str,
        category: str,
        route: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> int:
        sent = 0
        for token_entry in user_tokens:
            if token_entry.get("platform") == "ios":
                success = await self.send_push(
                    device_token=token_entry["token"],
                    title=title,
                    body=body,
                    category=category,
                    route=route,
                    metadata=metadata,
                )
                if success:
                    sent += 1
        return sent
