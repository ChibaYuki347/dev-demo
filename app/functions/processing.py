"""Pure business logic for the ETL function.

Imported from function_app.py wrapper and from tests directly — does not require
the Azure Functions host or any Service Bus / Identity SDK.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any


class InvalidPayloadError(ValueError):
    """Raised when an incoming Service Bus payload is missing required fields."""


REQUIRED_FIELDS = ("id", "event_type", "source")


def process_message(payload: dict[str, Any]) -> dict[str, Any]:
    """Transform a Salesforce-shaped event into the HubSpot-shaped event.

    This is the only function exercised by unit tests; the Service Bus trigger
    wrapper in function_app.py exists solely to invoke it.
    """
    _validate(payload)
    return {
        "id": payload["id"],
        "type": payload["event_type"],
        "source_system": payload["source"],
        "received_at": datetime.now(timezone.utc).isoformat(),
        "data": payload.get("data", {}),
    }


def _validate(payload: dict[str, Any]) -> None:
    missing = [f for f in REQUIRED_FIELDS if f not in payload]
    if missing:
        raise InvalidPayloadError(f"Missing required fields: {', '.join(missing)}")
