#!/usr/bin/env bash
# SPDX-FileCopyrightText: Canonical Ltd.
# SPDX-License-Identifier: Apache-2.0
#
# Export snapcraft credentials for publishing to latest/edge.
#
# Run this on a machine with snapcraft installed and authenticated
# (snapcraft login). The resulting token is saved to edge-credentials.
#
# Usage:
#   ./export-edge-credentials.sh

set -euo pipefail

SNAP_NAME="opencode"

snapcraft export-login \
  --snaps="${SNAP_NAME}" \
  --channels=latest/edge \
  --acls=package_upload,package_release \
  edge-credentials

echo "Credentials exported to edge-credentials"
