#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Canonical Ltd.
#
# Install the pkgproxy systemd unit (its RuntimeDirectory=/CacheDirectory= make
# systemd create /run/pkgproxy and /var/cache/pkgproxy, chowning the latter to
# root), start it, wait for its control sockets, then (optionally) point the
# host's apt and snapd at the proxy.
set -euo pipefail

# Render the unit file with the configured listen address and install it.
sudo mkdir -p /etc/systemd/system
sed "s|@ADDR@|${PKGPROXY_ADDR}|g" "${GITHUB_ACTION_PATH}/pkgproxy.service" \
    | sudo tee /etc/systemd/system/pkgproxy.service >/dev/null

sudo systemctl daemon-reload
sudo systemctl start pkgproxy.service

# Wait for both control sockets to appear; on timeout, dump the unit status and
# journal so a startup failure is diagnosable from the step log.
for _ in {1..100}; do
    if [ -S /run/pkgproxy/stats.sock ] && [ -S /run/pkgproxy/admin.sock ]; then
        break
    fi
    sleep 0.1
done

if [ ! -S /run/pkgproxy/stats.sock ] || [ ! -S /run/pkgproxy/admin.sock ]; then
    echo "::error::pkgproxy daemon did not create its control sockets in time" >&2
    sudo systemctl status pkgproxy.service --no-pager || true
    sudo journalctl -u pkgproxy.service --no-pager -n 100 || true
    exit 1
fi

if [ "${CONFIGURE_HOST}" = "true" ]; then
    pkgproxyctl setup apt -addr "${PKGPROXY_ADDR}" | sudo sh
    pkgproxyctl setup snap -addr "${PKGPROXY_ADDR}" | sudo sh
fi
