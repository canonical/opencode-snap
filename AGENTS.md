# AGENTS.md

## Project Overview

This repository packages the [OpenCode](https://github.com/anomalyco/opencode)
AI coding agent as a snap. It builds the application from source using Bun and
produces a CLI binary.

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

### Renovate

Renovate is configured via `renovate.json` to bump dependencies (bun) and opencode
versions automatically. The `source-tag` field in `snap/snapcraft.yaml`
references a specific OpenCode release tag (currently `v1.15.5`).

## Architecture

### snapcraft.yaml structure

Three parts in `snap/snapcraft.yaml`:

| Part         | Purpose                                                                                                                |
| ------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `bun`        | Dumps the Bun runtime binary (v1.3.14) to `/usr/local/bin/bun`, also creates `bunx` symlink                            |
| `opencode`   | Clones the source repo, builds the CLI binary with `bun run script/build.ts --baseline`, installs it to `bin/opencode` |
| `completion` | Installs bash completion and the `opencode.wrapper` shell wrapper from `snap/local`                                    |

### Snap apps

One app defined:

- **`opencode`** — CLI tool, invoked via `bin/opencode.wrapper` which unsets
  `SNAP_*` environment variables before exec. Completion via
  `usr/share/bash-completion/completions/opencode.opencode`. Environment:
  `OPENCODE_DISABLE_AUTOUPDATE=1`.

### Shell wrappers

The CLI app uses a wrapper script located in `snap/local/`:

- `opencode.wrapper` — unsets all `SNAP_*` env vars, execs `$SNAP/bin/opencode`

### Testing

Spread tests live in `tests/smoke/opencode/task.yaml`. Configured in
`spread.yaml` to run across Ubuntu 24.04, Ubuntu 26.04, Debian 13, and Fedora
43 using the `garden` backend (image-garden). The smoke test verifies the snap
is installed, launches without crashing, prints help output, and reports the
correct version (`1.15.5`).

## Key paths

| Path                             | Contents                    |
| -------------------------------- | --------------------------- |
| `snap/snapcraft.yaml`            | Main snap definition        |
| `snap/local/opencode.wrapper`    | CLI wrapper script          |
| `snap/local/opencode.opencode`   | Bash completion script      |
| `tests/smoke/opencode/task.yaml` | Smoke test                  |
| `spread.yaml`                    | Spread test configuration   |
| `.image-garden.mk`               | Image garden backend config |

## Important conventions

- Confinement is **classic** — full system access
- Base is **core24** (Ubuntu 24.04)
- Platforms: `amd64` (baseline only) and `arm64`
- The wrapper scripts follow the pattern: dump env, grep `^SNAP`, unset each,
  exec the real binary with all original args
- Pre-built snap artifacts may exist in the repo root (e.g.
  `opencode_1.15.3_amd64.snap`) but the CI builds from source
- Publishing credentials are in `publishing/export-*-credentials.sh`
