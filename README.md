# workflows

Shared [reusable GitHub Actions workflows][reusable] for my repositories.
Each workflow is defined once here; projects call it with a short stub, so
updating an action happens in one place.

## Available workflows

| Workflow | Purpose | Inputs |
| --- | --- | --- |
| [`markdownlint.yml`](.github/workflows/markdownlint.yml) | Lint Markdown with markdownlint-cli2 | `globs` (default `**/*.md`) |
| [`shell-lint.yml`](.github/workflows/shell-lint.yml) | shellcheck and shfmt (two jobs, pinned versions) | `paths` (default: every file `shfmt -f .` finds), `shfmt-flags` (default `-i 2 -sr -ci`) |
| [`docker-publish.yml`](.github/workflows/docker-publish.yml) | Build and test a Docker image; on the default branch, push it to Docker Hub and GHCR with provenance attestations | `image-name`, `test-command` (required); `test-platforms`, `platforms`, `context`, `build-args`, `tags`, `publish` |

## Usage

Add a stub workflow to the calling repository. Triggers and `concurrency`
belong in the stub. Lint rules stay in the calling repository's own
`.markdownlint.yaml`.

```yaml
---
name: markdownlint

on:
  pull_request:
    branches:
      - main

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  markdownlint:
    uses: chorrell/workflows/.github/workflows/markdownlint.yml@v1
    # with:
    #   globs: "docs/**/*.md"
```

Callers of `shell-lint.yml` use the same pattern; its checks report as
`<job id> / shellcheck` and `<job id> / shfmt`:

```yaml
jobs:
  shell-lint:
    uses: chorrell/workflows/.github/workflows/shell-lint.yml@v1
    # with:
    #   paths: "scripts/*.sh tests/**/*.bats"
```

shellcheck and shfmt versions are pinned with SHA-256 checksums in
`shell-lint.yml`'s `env` block. Dependabot does not update them; bump them by
hand alongside the `shellcheck-precommit` and `pre-commit-shfmt` hooks.

Callers of `docker-publish.yml` must grant the push job's permissions and pass
the Docker Hub secrets explicitly. GHCR uses `GITHUB_TOKEN`, so each GHCR
package must give the calling repository write access (Package settings →
Manage Actions access). Its checks report as `<job id> / test (<platform>)`
and `<job id> / push`:

```yaml
jobs:
  docker:
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
    uses: chorrell/workflows/.github/workflows/docker-publish.yml@v1
    with:
      image-name: pwgen
      test-command: docker run -i --rm "$IMAGE" -sycnB -1 25
    secrets:
      DOCKERHUB_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
      DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
```

### zizmor

zizmor requires hash pinning for every `uses:` by default. To call these
workflows by the `v1` tag, add `.github/zizmor.yml` to the calling repository:

```yaml
rules:
  unpinned-uses:
    config:
      policies:
        "chorrell/*": ref-pin
```

## Versioning

Callers reference the moving major tag, `v1`. Releases are automated with
[release-please](https://github.com/googleapis/release-please-action):

1. Changes merge to `main` with conventional-commit titles (`feat:` for a new
   workflow or input, `fix:` for a fix).
2. release-please opens or updates a release PR with the next version and
   `CHANGELOG.md`.
3. Merging the release PR tags `vX.Y.Z`, publishes a GitHub Release, and moves
   `v1` to it.

To pin an exact version instead of following `v1`, use a release tag, for
example `@v1.2.0`. Breaking changes (renamed inputs, different defaults) are
committed as `feat!:` and released as `v2.0.0` under a new `v2` tag; `v1` stays
where it was.

Third-party actions used here are SHA-pinned and updated by Dependabot.

[reusable]: https://docs.github.com/en/actions/sharing-automations/reusing-workflows
