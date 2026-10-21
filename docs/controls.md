# Controls catalogue

The catalogue of the **Baseline**: every control, its concern, whether it is Baseline or a
**Module**, the tool, the pin, and where findings go. Vocabulary: `GLOSSARY.md`.
Decisions: map #1 and `docs/adr/`.

Pins: `pins.env` (tools) and the `uses:` lines of `.github/workflows/` (actions, by full SHA).

## How a repo uses the Baseline

A repo has one caller file, `.github/workflows/security.yml`, made from
`templates/security.yml`. Each job calls one reusable workflow of this repo by full SHA:

```yaml
jobs:
  secrets:
    permissions:
      contents: read
      security-events: write   # public repos only
    uses: arnoldcastro5000/github-security/.github/workflows/secrets.yml@<sha> # v0.1.0
    with:
      upload-sarif: true       # public repos only
```

The reusable workflow checks out this repo at its own commit (`job.workflow_sha`), so the pins,
the scan scripts, and the rule packs always match the workflow version. Dependabot bumps the
SHA with a 7-day cooldown.

Every reusable workflow has one job, `scan`. So a required check is named
`<caller job> / scan`, for example `secrets / scan`.

## Baseline

Every in-scope repo gets these controls.

| Concern | Control | Tool | Gate | Findings |
|---|---|---|---|---|
| Secrets (`secrets.yml`) | Leaked secrets in every commit | gitleaks, betterleaks | any finding | log, summary, SARIF |
| | Verified live credentials in every commit | trufflehog `--results=verified` | any finding | log |
| | Weekly full-history scan | caller `schedule:` | as above | as above |
| | Repo rules and allowlists | repo `.gitleaks.toml` (extends the defaults) | | |
| | Opt-in rule packs | `config/rule-packs/` | | |
| Workflow security (`workflow-security.yml`) | Workflow and action security audit (online audits with the job token) | zizmor | any finding | log, summary, SARIF |
| | Workflow syntax and expressions | actionlint | any finding | log |
| Dependencies (`dependency-review.yml`) | A pull request adds a vulnerable dependency | dependency-review-action | any severity | PR check (public repos only) |
| Repo settings (Bootstrap) | Actions: `sha_pinning_required`, default token `read`, no PR approval by Actions | REST API | | |
| | Dependabot alerts and security updates; `delete_branch_on_merge` | REST API | | |
| | Public only: secret scanning, push protection, private vulnerability reporting, CodeQL default setup | REST API | | Security tab |
| | Public only: ruleset on the default branch: no deletion, no force push, PR required, Baseline checks required | REST API | | |
| Files (Bootstrap) | `dependabot.yml`: github-actions and each detected ecosystem, daily, `cooldown: default-days: 7` | `templates/dependabot.yml` | | Dependabot PRs |
| | Local guardrail: pre-push secrets scan of the pushed commits | `templates/pre-push` | blocks the push | terminal |

## Modules

A repo gets a Module when it contains that stack. Bootstrap detects the stack and adds the
caller job; `working-directory` points the Module at a subdirectory.

| Module | Controls | Tools | Gate |
|---|---|---|---|
| Python (`python.yml`) | Lint; SAST; known vulnerable packages (hash-pinned `requirements*.lock` first, then `requirements*.txt` without a lockfile) | ruff, semgrep `p/python`, pip-audit | any finding |
| Node (`node.yml`) | Lockfile hosts, HTTPS, and integrity; lockfile matches `package.json` (no install scripts); known vulnerable packages; SAST with the shared rules | lockfile-lint, `npm ci --ignore-scripts`, `npm audit`, semgrep `p/javascript p/typescript p/react` + `config/semgrep/` | npm audit: high and critical; others: any finding |
| Terraform (`terraform.yml`) | Format; validate (no backend, no credentials); lint; IaC misconfiguration | terraform, tflint, checkov, trivy config | trivy: high and critical; others: any finding |
| Container (`container.yml`) | Build (no push); image vulnerabilities | docker, trivy image | high and critical, fixable only |
| Shell (`shell.yml`) | Shell script lint (`*.sh`, `*.bash`, and sh or bash shebang files) | shellcheck | any finding |
| OPA (`opa.yml`) | Rego lint; policy unit tests | regal, conftest verify | any finding or failed test |

## Rule packs

Opt-in gitleaks rules, given in the `rule-packs` input of `secrets.yml`.

| Pack | Flags | Source |
|---|---|---|
| `aws-account-ids` | AWS account IDs (ARN, resource name, SQS URL, variable, ECR, IAM principal, console URL, array element, bare 12-digit token) | loonvault `.gitleaks.toml` |
| `cloud-resource-ids` | AWS resource IDs (sg, vpc, ami, subnet) and UUIDs (Azure subscription or tenant) | prowler-cspm-demo `hardcoded-config-check.yml` |
| `personal-emails` | Email addresses, except GitHub noreply and example domains | prowler-cspm-demo `hardcoded-config-check.yml` |

## Findings and suppression

- Every control fails its check on a finding.
- Every SARIF report becomes a table in the job summary (`scripts/sarif-summary.sh`).
- With `upload-sarif: true` (public repos), SARIF goes to the Security tab. Fork pull requests
  do not upload.

Suppress a false positive in the repo, in a pull request, with a reason:

| Tool | Suppression |
|---|---|
| gitleaks, betterleaks | the finding fingerprint in `.gitleaksignore`, or an allowlist in `.gitleaks.toml` |
| semgrep | `# nosemgrep: <rule-id>` (or `// nosemgrep: <rule-id>`) with a reason |
| ruff | `# noqa: <code>` with a reason |
| checkov | `# checkov:skip=<id>:<reason>` in the resource |
| trivy | the ID in `.trivyignore` with a reason |
| zizmor | `# zizmor: ignore[<audit>]` with a reason |
| shellcheck | `# shellcheck disable=<code>` with a reason |
| regal | `# regal ignore:<rule>` with a reason |

A real secret is never suppressed: rotate it first, then remove it.

## Private repos (GitHub Free)

Private repos run the same CI checks. GitHub Free withholds these controls from them
(research: map #1, "GitHub plans"):

| Control | Private repo on Free | What the Baseline does instead |
|---|---|---|
| Rulesets and required checks | not available | The checks still run and show red. Nothing blocks a merge. The drift audit reports the gap. |
| Secret scanning and push protection | not available | CI secrets scan on every push; the local pre-push hook |
| Code scanning (SARIF, CodeQL) | not available | Findings in the job log and the job summary |
| Dependency review | not available | Dependabot alerts (available); the Module audits (pip-audit, npm audit) |
| Private vulnerability reporting | public repos only | none |

## Inventory of the prior implementations

Status as of 2026-10-21. P = prowler-cspm-demo, L = loonvault, U = understand-greenstand,
H = hello-cloud-security. "path" = the workflow has a path filter.

| Control | P | L | U | H | Baseline |
|---|---|---|---|---|---|
| gitleaks | pre-commit hook v8.30.1 | CI v8.30.1 (curl, no checksum); pre-commit hook | CI v8.30.1 (SHA-256 pin); pre-push hook; SARIF | none | kept (Baseline) |
| betterleaks | CI v1.4.0 (checksum file of the release) | CI v1.5.0 (curl, no checksum) | CI v1.9.0 (SHA-256 pin); SARIF | none | kept, v1.9.0 |
| trufflehog | none | action v3.95.6 (SHA); verified + account-ID detectors | none | none | kept, binary v3.99.2 |
| AWS account-ID rules | grep workflow (`hardcoded-config-check.yml`) | gitleaks + trufflehog configs | none | none | moved to rule pack `aws-account-ids` |
| Resource-ID, UUID, email checks | grep workflow | none | none | none | moved to rule packs |
| Private repo names check | none | none | CI + pre-push (Greenstand names) | none | stays repo-local |
| Issue and PR text secrets scan | none | none | hourly betterleaks | none | stays repo-local (revisit) |
| zizmor | action v0.5.6; SARIF; path | pip v1.25.2 | none | none | kept, binary v1.30.1 |
| actionlint | none | v1.7.12 (curl) | none | none | kept |
| semgrep | v1.164.0, custom rules; SARIF; path | v1.166.0, registry rules | none | `semgrep-action@v1` (tag) | kept in Python and Node Modules; custom rules shared |
| CodeQL workflow | none | none | none | `codeql-action@v4` (tag) | replaced by CodeQL default setup (public) |
| ruff | unpinned; path | v0.15.17 | none | none | kept (Python) |
| bandit | unpinned; path | none | none | none | dropped: semgrep and ruff cover it |
| pip-audit | none | v2.10.1, lockfile-first loop | none | none | kept (Python) |
| npm audit | none | high | none | none | kept (Node) |
| lockfile-lint | v5.0.0; path | none | none | none | kept (Node) |
| Socket | none | action v1.3.2 (API key) | none | none | dropped from Baseline: paid key; stays repo-local in L |
| dependency-review | v5 (comment says v4); path | v5.0.0 | none | none | kept, no path filter |
| terraform fmt, validate | `~1.6`; path | `~1.9`, three stacks | none | none | kept (Terraform), 1.16.6 |
| tflint | none | v0.63.1 | none | none | kept, v0.64.0 |
| checkov | none | v3.3.1 | none | none | kept, v3.3.29 |
| trivy config | action v0.36.0; SARIF; never fails | none | none | none | kept, fails on high and critical |
| trivy image | action v0.36.0; high and critical | none | none | none | kept (Container) |
| shellcheck | `action-shellcheck@master` (SHA); path | none | none | none | kept (Shell), pinned binary |
| regal, conftest verify | none | v0.41.1, v0.56.0 | none | none | kept (OPA) |
| OPA plan gate | none | pre-push (needs AWS credentials) | none | none | stays repo-local |
| harden-runner | one workflow, audit mode | none | none | none | dropped: third-party telemetry, audit only; revisit |
| Repo-specific checks | eslint, tsc, build | docs-drift, compliance matrix | estate-index, drift-report | none | stay repo-local |
| Dependabot | daily, no cooldown | daily, cooldown 7 days | weekly, actions grouped | none | daily, cooldown 7 days |
| Ruleset | none | 1 review, 7 checks, admin bypass | 0 reviews, 4 checks | none | Bootstrap (public) |
| Secret scanning, push protection | on | on | on | on | Bootstrap (public) |
| Dependabot security updates | off | on | not checked | not checked | Bootstrap |
| Action pinning | SHA | SHA | SHA | tags | SHA, plus `sha_pinning_required` |
| Current status | 64 open code-scanning alerts (5 critical), 22 open Dependabot alerts | Supply chain and Docs drift fail on `main` | passing | passing | fix tickets #9, #10 |

Drift between the hand copies: betterleaks 1.4.0, 1.5.0, 1.9.0; three `actions/checkout` SHAs;
semgrep 1.164.0 and 1.166.0. Path filters (P) make a required check wait forever when a pull
request does not touch the path; the Baseline workflows have no path filters.

## Known limits of v0.1.0

- Python tools (semgrep, ruff, checkov, pip-audit) are pinned by version, not by hash.
- Semgrep registry rules (`p/python`, ...) are fetched at run time and are not pinned.
- `lockfile-lint` runs through `npx` at a pinned version, not by hash.
- shellcheck, actionlint, trufflehog, pip-audit, and npm audit write no SARIF; read the job log.
- `pins.env` is not tracked by Dependabot; bump it by hand (see the file header).
