"""Tests for processing.process_message().

These tests intentionally do NOT import function_app.py (which would require
azure-functions and the Service Bus binding extensions). They exercise the
pure business logic directly.
"""
from __future__ import annotations

import sys
from datetime import datetime
from pathlib import Path

import pytest

# Make `processing` importable regardless of where pytest is invoked from.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from processing import InvalidPayloadError, process_message  # noqa: E402


def _sample_payload() -> dict:
    return {
        "id": "evt-001",
        "event_type": "Account.Updated",
        "source": "salesforce",
        "data": {"AccountId": "001xx0000003DGb", "Name": "Acme"},
    }


def test_process_message_returns_transformed_event() -> None:
    result = process_message(_sample_payload())

    assert result["id"] == "evt-001"
    assert result["type"] == "Account.Updated"
    assert result["source_system"] == "salesforce"
    assert result["data"]["Name"] == "Acme"

    # received_at should be a parseable ISO-8601 timestamp
    datetime.fromisoformat(result["received_at"])


def test_process_message_preserves_empty_data() -> None:
    payload = _sample_payload()
    payload.pop("data")
    result = process_message(payload)
    assert result["data"] == {}


@pytest.mark.parametrize(
    "missing_field",
    ["id", "event_type", "source"],
)
def test_process_message_rejects_missing_required_field(missing_field: str) -> None:
    payload = _sample_payload()
    payload.pop(missing_field)
    with pytest.raises(InvalidPayloadError, match=missing_field):
        process_message(payload)


def test_process_message_rejects_multiple_missing_fields() -> None:
    with pytest.raises(InvalidPayloadError) as exc:
        process_message({"id": "x"})
    assert "event_type" in str(exc.value)
    assert "source" in str(exc.value)
