# SPDX-FileCopyrightText: Canonical Ltd.
# SPDX-License-Identifier: Apache-2.0

"""Read a /v1/models JSON response from stdin and print the first model id."""

import json
import sys

try:
    payload = json.load(sys.stdin)
    data = payload.get("data") or []
    model_id = data[0].get("id") if data and len(data) > 0 and isinstance(data[0], dict) else ""
except Exception:
    model_id = ""

print(model_id)
