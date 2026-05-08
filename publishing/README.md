## CI

Builds are triggered on push to `main`, `master`, `develop`, and on tags (`v*`).

- Branch builds publish to `latest/edge`
- Tag builds publish to `latest/candidate`

The CI builds for both amd64 and arm64 in parallel using GitHub-hosted runners
(`ubuntu-24.04` and `ubuntu-24.04-arm`).

## Managing Snap Store credentials

This project uses three credential files for different stages of the release
pipeline. Each file is a snapcraft login token scoped to a specific channel
and set of ACLs.

### Creating credentials

Run the corresponding export script on a machine where `snapcraft` is
installed and you are logged in (`snapcraft login`):

| Script                            | Output file             | Channels           | ACLs                              | Purpose                          |
| --------------------------------- | ----------------------- | ------------------ | --------------------------------- | -------------------------------- |
| `export-edge-credentials.sh`      | `edge-credentials`      | `latest/edge`      | `package_upload, package_release` | Upload builds from branches      |
| `export-candidate-credentials.sh` | `candidate-credentials` | `latest/candidate` | `package_upload, package_release` | Upload builds from tags          |
| `export-stable-credentials.sh`    | `stable-credentials`    | `latest/stable`    | `package_access, package_release` | Promote from candidate to stable |

### Storing credentials in GitHub

Save the contents of each credential file as a secret named
`SNAPCRAFT_STORE_CREDENTIALS` in the matching GitHub environment:

- `edge-credentials` → `latest/edge` environment
- `candidate-credentials` → `latest/candidate` environment
- `stable-credentials` → `latest/stable` environment

These environments can also have approval rules attached so that publishing
or promotion requires manual review.
