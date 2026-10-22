# Diagnosing-bugs notes

Repo-specific feedback loops, host limits, and known tool quirks for `/diagnosing-bugs`.
Redact every secret in what you show (the scanners already run with `--redact`).

## Feedback loops

1. **Self-test of one concern**: `tests/selftest.sh <concern>`. It prints one line per check
   (`<label>: pass|FAIL|skip`) for the clean and the dirty fixture, and the dirty log when an
   expectation fails.
2. **One scan script on any folder**: `BASELINE_OUT=$(mktemp -d) scripts/scan/<concern>.sh [options] <path>`.
   SARIF reports go to `$BASELINE_OUT`. Keep `$BASELINE_OUT` outside the scanned folder.
3. **CI**: check runs `gh api "repos/arnoldcastro5000/github-security/commits/<sha>/check-runs?per_page=100"`,
   then the job log `gh api repos/arnoldcastro5000/github-security/actions/jobs/<id>/logs`.
4. **Workflow-behavior spike**: for a question about GitHub Actions itself, push a throwaway
   branch with a small caller and called workflow, read the job log, then delete the branch.
   This loop proved `job.workflow_sha` (ADR-0001).

## Host limits (this sandbox)

- About 1 GB of free disk. The trivy vulnerability DB does not fit: run the container and
  terraform self-tests in CI only.
- `semgrep.dev` returns HTTP 403 from this host: registry rules (`p/python`, ...) work only in CI.
- No `xz` binary (`install-tool.sh` falls back to Python), no Python `venv` module (use
  `pip install --target`), and `timeout` is not executable.
- `gh` is 2.46: see `docs/agents/issue-tracker.md`.

## Known tool quirks

| Tool | Quirk |
|---|---|
| checkov | `--output-file-path` writes a file at the given path when the path does not exist yet. |
| zizmor | Exits non-zero on any finding, also on help level. Scans folders recursively (so fixtures use `.fixture`). Flags `./` local refs (self-repository audit). |
| actionlint 1.7.12 | Does not know `job.workflow_*` or `uses: $/...`; `.github/actionlint.yaml` ignores those two messages. |
| trufflehog 3.99 | Use `--results=verified --fail --no-update`; `--only-verified` is gone. |
| shellcheck 0.11 | SC2329 for a function that `check` calls indirectly: disable per function, with the reason. A single file without `-x` reports SC1091 for `lib.sh`. |
| semgrep | Rule IDs from a local config are dotted paths (`config.semgrep.js-no-eval`). |
| GitHub | A skipped job counts as a pass for a required check. Code scanning accepts gitleaks and betterleaks SARIF in one upload with one category. |
