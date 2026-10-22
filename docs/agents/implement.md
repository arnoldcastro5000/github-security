# Implement notes

Repo-specific rules for `/implement` (and any change to this repo). Durable facts go here or
in issues, not in Claude memory.

## What "the test suite" is here

There is no build, typecheck, or unit test framework. The checks are:

| Check | Command | Where |
|---|---|---|
| Self-test of one concern | `tests/selftest.sh <concern>` (secrets, workflow-security, python, node, terraform, container, shell, opa) | local and `selftest.yml` |
| Shell lint | `shellcheck scripts/*.sh scripts/scan/*.sh tests/selftest.sh templates/pre-push` (give all scripts as input, or use `-x`) | local and `ci.yml` (shell) |
| Workflow lint | `actionlint` (reads `.github/actionlint.yaml`) and `zizmor .` | local and `ci.yml` |
| Full suite | open a PR: `selftest.yml` and `ci.yml` run every check | CI |

Install pinned tools for local runs: `BASELINE_BIN_DIR=/tmp/<dir>/bin scripts/install-tool.sh <tool>...`,
then put that dir on `PATH`. Python tools need `pipx`, or `pip install --target`. Host limits:
`docs/agents/diagnosing-bugs.md`.

## Conventions

- **A new or changed control** needs four things together: a `check <label> ...` line in
  `scripts/scan/<concern>.sh`, a clean and a dirty fixture under `tests/fixtures/<concern>/`,
  the `expect-fail` (and `expect-rules`) lines, and the row in `docs/controls.md`.
- **Fixture files** that another tool would act on in this repo (workflows, manifests,
  lockfiles, Dockerfiles, source with planted bugs) carry a `.fixture` suffix. The self-test
  removes it in a temp copy.
- **Reusable workflow shape**: one job `scan`; no job `permissions:` (the caller grants them);
  check out this repo at `${{ job.workflow_sha }}` into `.baseline`, then move it to
  `$RUNNER_TEMP/baseline`; load `pins.env` into `GITHUB_ENV`; `upload-sarif` input; skip the
  upload on fork PRs. Copy an existing workflow.
- **Same-repo refs** use the self-repository syntax `uses: $/...`, not `./...`.
- **Actions** are pinned by full SHA with a version comment.
- **Tool pins** (`pins.env`): the newest release that is at least 7 days old. Bump the
  version, URL, and SHA-256 together; take the SHA-256 from the release asset digest.
- **Executable bits**: on this host, `sed -i` and new files can lose the executable bit.
  Run `chmod +x` and check `git ls-files -s` (mode `100755`) before a commit.
- **Writing**: no em dash in any file (`grep -rP '\x{2014}'`). Simplified Technical English.
- **Public repo**: never write a private repo name, a personal email, or a real secret.

## Git

- Commit with the global git identity (the `arnoldcastro5000` noreply address). Never add a
  co-author trailer. Before a push, check `git log --format='%an <%ae>'`.
- Work on a branch and open a PR. Write the PR body with the `pr` skill.
- **Merge locally**, then push the base branch: `git switch main && git merge --ff-only <branch>`
  (or a local merge commit) and `git push`. The PR closes as merged.
  **Never** use `gh pr merge` or the GitHub merge button: GitHub writes the account email into
  the merge commit. This happened on 2026-10-21 (PR #11), and `main` was force-pushed back to
  the branch tip.

## Release

1. Wait until `CI` and `Self-test` pass on `main`.
2. `gh release create vX.Y.Z -R arnoldcastro5000/github-security --target <full sha> --notes-file <file>`.
   Immutable releases are on, so a tag never moves.
3. The notes show the full SHA in a `uses:` example line.
