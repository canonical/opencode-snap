# AGENTS.md

## Project Overview

This repository packages the [OpenCode](https://github.com/anomalyco/opencode)
AI coding agent as a snap. The CLI and desktop GUI are both built from source
using Bun, with the desktop GUI compiled via Electron.

## Build & Release Workflow

### Building locally

```bash
snapcraft pack
```

This produces an `.snap` file in the project root.

### CI/CD pipelines

All CI workflows live under `.github/workflows/`:

| Workflow                | Purpose                                      |
| ----------------------- | -------------------------------------------- |
| `snapcraft-pack.yml`    | Builds the snap in GitHub Actions            |
| `snapcraft-upload.yml`  | Uploads to a staging PPA/store channel       |
| `snapcraft-promote.yml` | Promotes from staging to production channels |
| `tasteful-crafts.yml`   | Shared build/test/publish workflow           |
| `spread.yml`            | Integration tests via spread                 |

The `build.yml` entrypoint runs when `snap/snapcraft.yaml`, `spread.yaml`,
`tests/**`, or `.image-garden.mk` change. It triggers on push to `main`,
`master`, `develop`, and on `v*` tags, as well as on pull requests.

### External actions

| Action                                                              | Purpose                                                                                                                          |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| [`zyga/setup-pkgproxy@v1`](https://github.com/zyga/setup-pkgproxy) | Build and run [pkgproxy](https://gitlab.com/zygoon/pkgproxy) as a caching proxy for apt/snap/go/LXD traffic, with a persistent payload cache; used by `snapcraft-pack.yml`, `snapcraft-upload.yml`, `snapcraft-promote.yml`, `spread.yml`, and `tasteful-crafts.yml` |

`setup-pkgproxy` builds a pinned pkgproxy version (its own `version` input
default — callers here no longer pass `version:` explicitly, so bumping the
pin is a one-file change in that repo, not an edit in every caller),
installs the binary to `/usr/local/bin`, installs a `pkgproxy.service`
systemd unit whose `RuntimeDirectory=`/`CacheDirectory=` create
`/run/pkgproxy` and `/var/cache/pkgproxy`, starts the daemon, and points the
host's apt/snapd at the proxy. It exposes `package-cache-hit` and
`package-cache-key-success` / `package-cache-key-partial` outputs so the caller
saves the payload cache under the same stable per-arch key the restore used,
only on a cache miss. Snapcraft-specific LXD wiring (the build container
profile, pre-start hook, and image remote) stays in `snapcraft-pack.yml`.

### Renovate

Renovate is configured via `renovate.json` to bump dependencies (bun) and opencode
versions automatically. The `source-tag` field in `snap/snapcraft.yaml`
references a specific OpenCode release tag (currently `v1.15.10`).

## Architecture

### snapcraft.yaml structure

Four parts in `snap/snapcraft.yaml`:

| Part                     | Purpose                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `bun`                    | Dumps the Bun runtime binary (v1.3.14) to `/usr/local/bin/bun`, also creates `bunx` symlink                            |
| `opencode-cli`           | Clones the source repo, builds the CLI binary with `bun run script/build.ts --baseline`, installs it to `bin/opencode` |
| `opencode-desktop`       | Builds the Electron desktop GUI from source, patches package.json for snap compatibility, installs to component dir    |
| `opencode-configuration` | Installs bash completion, shell wrappers, and the `.desktop` file from `snap/local`                                    |

### Snap apps

Two apps defined:

- **`opencode`** — CLI tool, invoked via `bin/opencode.wrapper` which unsets
  `SNAP_*` environment variables before exec. Completion via
  `usr/share/bash-completion/completions/opencode.opencode`. Environment:
  `OPENCODE_DISABLE_AUTOUPDATE=1`.
- **`desktop`** — Electron desktop GUI, invoked via `bin/opencode-desktop.wrapper`
  which unsets `SNAP_*` env vars, auto-installs the snap component if missing,
  and launches the Electron app from the snap component directory. The `desktop`
  app declares a `desktop` file association for desktop integration.

### Snap components

The desktop GUI is packaged as a snap component (`desktop`, type: standard).
Components are independently installable/upgradeable sub-units of a snap.
The desktop binary lives at `$SNAP/../components/$SNAP_REVISION/desktop/@opencode-aidesktop`
and the wrapper auto-triggers `snapctl install +desktop` if the component is
not yet installed (e.g. on first launch).

### Shell wrappers

Both apps use wrapper scripts located in `snap/local/`:

- `opencode.wrapper` — unsets all `SNAP_*` env vars, execs `$SNAP/bin/opencode`
- `opencode-desktop.wrapper` — unsets `SNAP_*` env vars, auto-installs the desktop
  snap component via `snapctl install +desktop` if not yet present, then execs
  the Electron binary at `$SNAP/../components/$SNAP_REVISION/desktop/@opencode-aidesktop`

### Testing

Spread tests live in `tests/smoke/opencode/task.yaml`. Configured in
`spread.yaml` to run across Ubuntu 24.04, Ubuntu 26.04, Debian 13, and Fedora
43 using the `garden` backend (image-garden). The smoke test verifies the snap
is installed, launches without crashing, prints help output, and reports the
correct version (`1.15.5`). Desktop binaries are available as:
- `opencode-desktop-linux-amd64.deb` for amd64
- `opencode-desktop-linux-arm64.deb` for arm64

## Key paths

| Path                                  | Contents                    |
| ------------------------------------- | --------------------------- |
| `snap/snapcraft.yaml`                 | Main snap definition        |
| `snap/local/opencode.wrapper`         | CLI wrapper script          |
| `snap/local/opencode-desktop.wrapper` | Desktop GUI wrapper script  |
| `snap/local/opencode.opencode`        | Bash completion script      |
| `tests/smoke/opencode/task.yaml`      | Smoke test                  |
| `spread.yaml`                         | Spread test configuration   |
| `.image-garden.mk`                    | Image garden backend config |

## Important conventions

- Confinement is **classic** — full system access
- Base is **core24** (Ubuntu 24.04)
- Platforms: `amd64` (baseline only) and `arm64`
- The wrapper scripts follow the pattern: dump env, grep `^SNAP`, unset each,
  exec the real binary with all original args
- Pre-built snap artifacts may exist in the repo root (e.g.
  `opencode_1.15.3_amd64.snap`) but the CI builds both the CLI and desktop GUI from source
- Publishing credentials are in `publishing/export-*-credentials.sh`
