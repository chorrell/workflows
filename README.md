# workflows

Shared [reusable GitHub Actions workflows][reusable] for my repositories.
Each workflow is defined once here; projects call it with a short stub, so
updating an action happens in one place.

## Available workflows

| Workflow | Purpose | Inputs |
| --- | --- | --- |
| [`markdownlint.yml`](.github/workflows/markdownlint.yml) | Lint Markdown with markdownlint-cli2 | `globs` (default `**/*.md`) |
| [`shell-lint.yml`](.github/workflows/shell-lint.yml) | shellcheck and shfmt (two jobs, pinned versions) | `paths` (default: every file `shfmt -f .` finds), `shfmt-flags` (default `-i 2 -sr -ci`) |

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

Callers reference the moving `v1` tag. Non-breaking changes go to `main`, and
then `v1` is moved forward:

```sh
git tag -f v1 && git push -f origin v1
```

Breaking changes (renamed inputs, different defaults) get a new `v2` tag.
Third-party actions used here are SHA-pinned and updated by Dependabot.

[reusable]: https://docs.github.com/en/actions/sharing-automations/reusing-workflows
