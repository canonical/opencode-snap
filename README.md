# opencode snap

This repository contains snap packaging for
[opencode-ai](https://github.com/anomalyco/opencode).

It does not build opencode from source. Instead, it downloads a single prebuilt
binary from the upstream [GitHub
releases](https://github.com/anomalyco/opencode/releases) and packages it into
a snap.

## Building

```sh
snapcraft pack
```

## Updating the version

The version is pinned in `snap/snapcraft.yaml` — the version string in each
source URL (currently `1.14.41`).

To update to a new upstream release, change the version in all source URLs and
commit.

## Testing with spread

Tests in this repository use [spread](https://github.com/snapcore/spread), the
multi-machine test runner from the snap core team. To run the tests locally you
need a spread environment backed by a LXD image.

Install the `image-garden` snap, which provides the image management tooling
spread depends on:

```sh
sudo snap install image-garden
```

The `image-garden` snap ships a `image-garden.spread` binary that acts as a
spread backend. Use it to run the tests:

```sh
image-garden.spread
```

This will pull the necessary virtual machine base images, and execute the test
cases defined under `tests/`.

## Publishing

See `publishing/README.md` for details.
