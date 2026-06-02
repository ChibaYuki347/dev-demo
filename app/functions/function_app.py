"""Azure Functions v2 app — thin trigger wrappers around pure logic in processing.py.

The trigger wrappers exist purely to bridge the Functions runtime to the testable
`process_message()` function. All real logic lives in processing.py so we can
unit-test without spinning up the Functions host.

Service Bus uses Managed Identity, not a connection string:
    Setting key:  ServiceBusConnection__fullyQualifiedNamespace
    Value:        <namespace>.servicebus.windows.net
The `connection=` parameter below is the *prefix* of that setting key.
"""
from __future__ import annotations

import json
import logging

# `azure.functions` is required at runtime (Functions host). The unit tests
# never import this module, so its absence at test time is fine.
import azure.functions as func

from processing import process_message

logger = logging.getLogger(__name__)

app = func.FunctionApp()


@app.service_bus_topic_trigger(
    arg_name="message",
    topic_name="etl-events",
    connection="ServiceBusConnection",
    subscription_name="sf-to-hubspot",
)
def sf_to_hubspot(message: func.ServiceBusMessage) -> None:
    """Salesforce → HubSpot ETL bridge."""
    payload = json.loads(message.get_body().decode("utf-8"))
    result = process_message(payload)
    logger.info("Processed message id=%s -> result=%s", payload.get("id"), result)
