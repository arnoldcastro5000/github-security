# ADR-0001: Public source repo with reusable workflows pinned by SHA

Date: 2026-10-21. Status: accepted. Map #1, ticket "Distribution mechanism".

## Context

Four repos copy their CI security controls by hand, and the copies drift. The account is a
personal account on GitHub Free with 7 public and 9 private in-scope repos. A private source
repo can share reusable workflows with private repos only, so it cannot serve the 7 public
repos. Template repos copy files once and keep no link. File-sync tools copy files but apply
no repo settings, and the most used one has had no commit since 2024-05.

## Decision

- `github-security` is public and is the single source of the Baseline.
- Each in-scope repo calls the Baseline through reusable workflows, pinned by full SHA with a
  version comment (`@<sha> # v0.1.0`). Dependabot bumps the pin with a 7-day cooldown.
- A reusable workflow checks out `github-security` at its own commit, `job.workflow_sha`, and
  reads `pins.env`, the scan scripts, and the rule packs from there. A spike on 2026-10-21
  confirmed that `job.workflow_sha` is the called workflow's commit, not the caller's.
- The scan logic lives in plain scripts (`scripts/scan/`), not in composite actions. A local
  composite action must be inside the workspace, and the Baseline checkout must stay outside
  the workspace so that scanners do not scan it. Scripts also run in the self-test and on a
  developer machine.
- A Bootstrap script over the `gh` API writes the caller file and applies repo settings. Files
  alone cannot apply settings.
- Releases are semver tags, published as immutable releases.

## Consequences

- The Baseline content is public. It must never hold a private repo name or a real secret.
- One change in `github-security` reaches every repo through Dependabot PRs; no repo copies
  scan logic.
- A caller job sets the permissions; a private repo omits `security-events: write` and sets
  `upload-sarif: false`.
- actionlint 1.7.12 does not know `job.workflow_*` or the `$/` syntax yet; this repo ignores
  those two messages in `.github/actionlint.yaml`.
