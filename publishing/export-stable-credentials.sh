#!/usr/bin/env bash
# SPDX-FileCopyrightText: Canonical Ltd.
# SPDX-License-Identifier: Apache-2.0
#
# Export snapcraft credentials for promoting from latest/candidate to latest/stable.
#
# Run this on a machine with snapcraft installed and authenticated
# (snapcraft login). The resulting token is saved to stable-credentials.
#
# Usage:
#   ./export-stable-credentials.sh

set -euo pipefail

SNAP_NAME="opencode"

snapcraft export-login \
  --snaps="${SNAP_NAME}" \
  --channels=latest/stable \
  --acls=package_access,package_release \
  stable-credentials

echo "Credentials exported to stable-credentials"
