# workflows

Shared [reusable GitHub Actions workflows][reusable] for my repositories.
Each workflow is defined once here; projects call it with a short stub, so
updating an action happens in one place.

## Available workflows

| Workflow | Purpose | Inputs |
| --- | --- | --- |
| [`markdownlint.yml`](.github/workflows/markdownlint.yml) | Lint Markdown with markdownlint-cli2 | `globs` (default `**/*.md`) |
| [`shell-lint.yml`](.github/workflows/shell-lint.yml) | shellcheck and shfmt (two jobs) | `paths` (default: every file `shfmt -f .` finds), `shfmt-flags` (default `-i 2 -sr -ci`) |
| [`docker-publish.yml`](.github/workflows/docker-publish.yml) | Build and test a Docker image; on the default branch, push it to Docker Hub and GHCR with provenance attestations | `image-name`, `test-command` (required); `test-platforms`, `platforms`, `context`, `build-args`, `tags`, `publish` |
| [`zizmor.yml`](.github/workflows/zizmor.yml) | Audit the repository's GitHub Actions workflows with zizmor | none |
| [`pre-commit.yml`](.github/workflows/pre-commit.yml) | Run every hook in the caller's `.pre-commit-config.yaml` on all files, with prek | `skip` (comma-separated hook ids) |
| [`dependabot-automerge.yml`](.github/workflows/dependabot-automerge.yml) | Enable auto-merge on Dependabot PRs for one group when every update is minor or patch | `dependency-group` (default `tooling`), `app-client-id`; secret `APP_PRIVATE_KEY` |
| [`terraform-validate.yml`](.github/workflows/terraform-validate.yml) | `terraform fmt`, `init` (no backend), `validate` and `tflint` for one root module | `working-directory` (default `.`), `terraform-version` (default `~1.16`), `lockfile-readonly` (default `false`), `validate-env` (JSON object) |

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

shellcheck and shfmt come from the SHA-pinned `taiki-e/install-action`,
which installs the newest version in its bundled, checksummed manifests, so
Dependabot's update of that action also upgrades the tools.

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

Callers of `zizmor.yml` use the same stub pattern, triggered on
`pull_request` and on pushes to `main`. Its check reports as
`<job id> / zizmor`:

```yaml
jobs:
  zizmor:
    uses: chorrell/workflows/.github/workflows/zizmor.yml@v1
```

The zizmor version is the one pinned in the SHA-pinned
`zizmorcore/zizmor-action` release (its default `version: latest`), so
Dependabot's update of that action also upgrades zizmor.

zizmor requires hash pinning for every `uses:` by default. To call these
workflows by the `v1` tag, add `.github/zizmor.yml` to the calling repository:

```yaml
rules:
  unpinned-uses:
    config:
      policies:
        "chorrell/*": ref-pin
```

### terraform-validate

`terraform-validate.yml` checks one Terraform root module. Its check reports
as `<job id> / validate`. A repository with several roots calls it from a
matrix job, one root per entry. `validate-env` sets environment variables for
`terraform validate` only, for placeholder provider settings that validate
reads but never uses; don't pass secrets in it.

```yaml
jobs:
  terraform:
    uses: chorrell/workflows/.github/workflows/terraform-validate.yml@v1
    with:
      working-directory: terraform
      lockfile-readonly: true
      # validate-env: '{"GITHUB_APP_ID": "0"}'
```

A required check that should keep its name, such as `Terraform Validation`,
belongs on a gate job in the caller that `needs:` the call, because the
called job's check is always prefixed with the caller's job id.

### pre-commit and Dependabot auto-merge

`pre-commit.yml` runs the caller's hooks in CI, so a Dependabot bump to a hook
is tested before it merges. Its check reports as `<job id> / pre-commit`. It
runs the hooks with [prek](https://github.com/j178/prek), a drop-in pre-commit
replacement that reads the same config. The prek version comes from the
SHA-pinned `j178/prek-action` (`prek-version: latest-known`), so Dependabot's
update of that action also upgrades prek.

`dependabot-automerge.yml` enables auto-merge on a Dependabot PR when the PR
belongs to `dependency-group` and every update in it is minor or patch. GitHub
then squash-merges it once the required checks pass, so the repository needs a
required check that exercises the update (`pre-commit / pre-commit` for hooks).
Majors, other groups and security updates are left for review.

Put GitHub Actions and pre-commit hooks in one multi-ecosystem group named
`tooling` in `.github/dependabot.yml` (see this repository's), and keep
ecosystems that need review, such as uv or Docker, out of it.

```yaml
name: dependabot-automerge

on:
  pull_request:

permissions:
  contents: read

jobs:
  dependabot-automerge:
    permissions:
      contents: write
      pull-requests: write
    uses: chorrell/workflows/.github/workflows/dependabot-automerge.yml@v1
```

A merge made with `GITHUB_TOKEN` does not trigger `push` workflows. A
repository that publishes or deploys on pushes to `main` should not call this
workflow, or should pass a GitHub App to merge as: `app-client-id` and an
`APP_PRIVATE_KEY` *Dependabot* secret (Dependabot runs can't read Actions
secrets).

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
