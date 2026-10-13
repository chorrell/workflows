# AGENTS.md

Shared reusable GitHub Actions workflows (`on: workflow_call`) for my repositories. Each workflow is defined once
here, and other repos call it with a short stub, so action updates happen in one place. See `README.md` for usage.

## Commands

```bash
# Run all hooks (gitleaks, markdownlint, zizmor, whitespace/YAML checks)
pre-commit run --all-files

# Audit workflows only
zizmor .github/
```

## Layout

```text
.github/workflows/markdownlint.yml   # Reusable: Markdown lint (input: globs)
.github/workflows/shell-lint.yml     # Reusable: shellcheck + shfmt (inputs: paths, shfmt-flags)
.github/workflows/ci.yml             # Self-test: zizmor audit + calls the reusable workflows on this repo
.github/dependabot.yml               # Bumps SHA-pinned actions and pre-commit hooks
tests/fixtures/                      # Files the self-tests lint (e.g. example.sh for shell-lint)
```

## Conventions

- **Reusable workflows own the job, callers own the triggers.** Keep `on:`, `concurrency` and caller-specific
  `permissions` out of the reusable files; they go in each caller's stub. `concurrency` in a called workflow
  collides with the caller's group, because `github.workflow` resolves to the caller's name.
- **Callers use the moving `v1` tag.** Any change on `main` reaches every caller once `v1` is moved, so changes must
  stay backward compatible: add inputs with defaults, never rename or remove them. Breaking changes need a `v2` tag.
- **Pin third-party actions by full SHA** with a `# vX.Y.Z` comment; Dependabot updates them.
- **Per-repo config stays in the caller.** For example, markdownlint rules come from the caller's
  `.markdownlint.yaml`, because the reusable workflow checks out the calling repo.
- **Use `$/` for same-repo references** (`uses: $/.github/workflows/markdownlint.yml`), as zizmor's
  `self-repository` audit requires. actionlint does not support `$/` yet, so it is not used here; zizmor is the
  workflow linter.
- **Every new reusable workflow** gets a call from `ci.yml` and a row in the README table. Once that PR is
  merged, add its self-test checks (`<ci.yml job id> / <job name>`, exactly as `gh pr checks` reported them) to the
  `main-default` ruleset's required status checks. New checks are not required automatically, so a later change
  that breaks the workflow could otherwise merge. Don't add them before the merge: until `ci.yml` on `main` runs the
  job, every other open PR waits on a check it never reports.

## Git and Pull Requests

- All changes go through a pull request. Branch from `main` as `feature/<description>` or `fix/<description>`.
- Commit messages and PR titles use conventional commits (`feat: ...`, `fix: ...`, `ci: ...`, `docs: ...`).
- Keep PR descriptions brief: a few bullets or one paragraph on what changed and why. No AI attribution lines.
- PRs are squash-merged. After merging a change to a reusable workflow, move the tag:
  `git tag -f v1 && git push -f origin v1`. Do not move `v1` without being asked.

## Gotchas

- `ubuntu-slim` runners have no Docker. zizmor-action runs zizmor in Docker, so the `zizmor` job uses
  `ubuntu-latest`.
- Callers that run zizmor need `.github/zizmor.yml` with a `"chorrell/*": ref-pin` policy, or zizmor rejects the
  `@v1` reference (its default policy requires hash pinning).
