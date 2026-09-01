#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Canonical Ltd.
#
# Build the pinned pkgproxy binary into .cache/pkgproxy-bin (restored from the
# binary cache when possible), then install it to /usr/local/bin so the daemon
# unit (pkgproxy.service) and later pkgproxyctl steps use a stable, FHS-correct
# path. The binary dispatches on argv[0], so it is linked under both names.
set -euo pipefail

mkdir -p .cache/pkgproxy-bin
if [ ! -x .cache/pkgproxy-bin/pkgproxy ]; then
    GOBIN="$PWD/.cache/pkgproxy-bin" go install "gitlab.com/zygoon/pkgproxy/cmd/pkgproxy@${PKGPROXY_VERSION}"
fi

# Install to /usr/local/bin: a stable path the systemd unit's ExecStart can name
# directly, and already on the default PATH (/usr/local/bin) for every later
# step's pkgproxyctl calls, so no GITHUB_PATH manipulation is needed.
sudo install -m 0755 .cache/pkgproxy-bin/pkgproxy /usr/local/bin/pkgproxy
sudo ln -sf pkgproxy /usr/local/bin/pkgproxyctl
