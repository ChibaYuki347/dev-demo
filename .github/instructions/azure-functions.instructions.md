---
applyTo: "app/functions/**/*.py"
---

# Azure Functions Instructions

Path-scoped overrides for `app/functions/`.

## Architecture rule (most important)
- `function_app.py` contains only **thin trigger wrappers**.
- All business logic lives in `pure` functions in sibling modules (e.g. `processing.py`) and accepts/returns plain dicts.
- This makes unit tests possible without spinning up the Functions host or installing the Core Tools.

```python
# function_app.py
@app.service_bus_topic_trigger(
    arg_name="message",
    topic_name="etl-events",
    connection="ServiceBusConnection",  # see local.settings.json.example
    subscription_name="sf-to-hubspot",
)
def sf_to_hubspot(message: func.ServiceBusMessage) -> None:
    payload = json.loads(message.get_body().decode("utf-8"))
    result = process_message(payload)            # ← pure
    logging.info("processed: %s", result)
```

```python
# processing.py — testable without azure-functions runtime
def process_message(payload: dict) -> dict:
    ...
```

## Service Bus connection
- ALWAYS use Managed Identity. The setting key is `ServiceBusConnection__fullyQualifiedNamespace` and its value is `xxx.servicebus.windows.net` (no `Endpoint=sb://...;SharedAccessKey=...`).
- The trigger's `connection=` parameter is the **prefix** of that setting key.

## Style
- `from __future__ import annotations` at the top of every file.
- Full type hints; `mypy --strict` clean (run via `pytest --mypy` if added).
- `logging.getLogger(__name__)` instead of `print` or root logger.
- Time: always `datetime.now(timezone.utc)`. No naive datetimes.

## Tests
- Live in `app/functions/tests/`. Run with `pytest -q` from `app/functions/`.
- Test the pure functions (`processing.py`) directly with dict fixtures.
- One thin "wrapper smoke test" per trigger that mocks `func.ServiceBusMessage` and asserts the pure function is called.
- Coverage target ≥ 80% for `processing.py`. Wrapper coverage is not enforced.

## Dependencies
- Pin in `requirements.txt` with `==` for reproducibility.
- Keep azure-only deps (`azure-identity`, `azure-servicebus`) optional / lazily imported if they're not needed for the demo's `process_message`.
