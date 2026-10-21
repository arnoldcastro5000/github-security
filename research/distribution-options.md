# Distribution options for the Baseline

Research for issue #3 (map: issue #1). Date: 2026-10-21.

Question: which mechanisms can ship a **Baseline** from one repo (`github-security`) to many repos on one personal account on GitHub Free, and how does each stay current?

Context: `arnoldcastro5000` is a personal account (type `User`, verified live) on GitHub Free. There are 16 in-scope repos: 7 public, 9 private. The source repo `github-security` is private (verified live).

This file reports facts and trade-offs. The decision belongs to a later grilling ticket.

## Key findings

1. **A private source reaches only private repos.** A personal account can share actions and reusable workflows from a private repo with other private repos of the same user. The setting is "Accessible from repositories owned by the user" (REST `access_level: user`). The docs state: "Access is allowed only from private repositories." [S1][S2][S3] The visibility table states that a public caller can use only public workflows. [S4] So the 7 public in-scope repos **cannot** call a private `github-security`.
2. **The access setting has no plan gate and no direct cost.** The changelog names "user account" as a supported owner. [S2] The REST docs name no plan restriction. [S3] A live `GET .../actions/permissions/access` on `github-security` returns `{"access_level":"none"}`, not a 403 plan error (verified live). The setting is still `none` today. This research did not change it.
3. **Billing goes to the caller.** "Billing for GitHub-hosted runners is always associated with the caller." [S4] Public repos on standard runners are free. Private repos on Free share 2,000 minutes per month, and usage is blocked at quota without a payment method. [S5] The source visibility does not change who pays.
4. **A public source reaches all 16 repos.** A private caller can use public workflows. [S4] Two ways exist: make `github-security` public, or split the shared workflows and actions into a separate public repo. Trade-off: a public source exposes the Baseline content (scanner rules, allowlists). `understand-greenstand` treats private repo names as sensitive (it runs a private-name check before it posts text), so a public source must not contain private repo names.
5. **Repo settings are the weak point on Free, not files.** On private repos, rulesets and branch protection return `403 "Upgrade to GitHub Pro or make this repository public"` (verified live on `github-security` and `<private-repo>`). Code scanning default setup returns 403 on a private repo and works on a public repo (verified live). Secret scanning and push protection show as enabled on public `loonvault` and are absent on private `<private-repo>` (verified live). No file-based mechanism can apply these settings; only an API caller can, and only where the plan allows it.
6. **Prior art drifts already.** `loonvault` and `prowler-cspm-demo` copy workflows by hand. Their secret scan pins differ: betterleaks 1.5.0 vs 1.4.0, and two different `actions/checkout` SHAs (v6.0.3 vs v6) (verified live).

## Mechanisms

### 1. Reusable workflows (`on: workflow_call`)

- Each repo keeps a thin caller file: `jobs.x.uses: owner/repo/.github/workflows/x.yml@<ref>`. The ref "can be a SHA, a release tag, or a branch name". The docs call the SHA "the safest option". [S6]
- Limits: 10 levels of nesting, 50 unique reusable workflows per caller file. Workflow-level `env` does not propagate. The called workflow can only downgrade `GITHUB_TOKEN` permissions. The `github` context belongs to the caller. [S4]
- `secrets: inherit` is documented for callers "in the same organization or enterprise". [S6] The docs do not state it for a personal account. Named secrets work in all cases.
- Per-repo overrides and Modules: typed `inputs` (boolean, number, string) and one caller job per Module. [S6] The caller cannot add steps inside a called job.
- The caller file itself still has to reach each repo, so this mechanism needs a Bootstrap or a sync for the stub.

### 2. Composite actions

- Steps, not jobs. They run inside the caller job, so the caller keeps its runner and permissions and can add steps around them. [S7]
- Composite actions "cannot use secrets" directly; the caller passes values as inputs. Up to 10 nested composite actions per workflow. [S7]
- The same private-repo access rule as reusable workflows applies. [S1]
- Good fit for a shared step such as "install a pinned scanner with a checksum". Each repo still owns its workflow files.

### 3. Template repos

- A new repo gets "the same directory structure and files" of the default branch, optionally all branches, as a single commit with unrelated history. [S8][S9] Git LFS files are not included. [S9]
- The docs list only files and branches. They do not list settings, rulesets, branch protection, secrets, labels, or Actions settings as copied. [S8][S9] This research treats those as not copied (not verified live: verification needs a new repo).
- The new repo has no link to the template. Template changes never reach existing repos. [S8]
- One command exists: `POST /repos/{template_owner}/{template_repo}/generate` (or `gh repo create --template`). The caller must own a private template. [S10]
- Template use does not help Retrofit, because the 16 repos already exist.
- Workflow templates in a `.github` repo are an organization feature. [S7] They do not apply to a personal account.

### 4. Bootstrap script over the `gh` API

What the REST API can set on Free (by visibility):

| Setting | Endpoint | Public repo | Private repo |
| --- | --- | --- | --- |
| Merge options, `delete_branch_on_merge`, `has_wiki`, `web_commit_signoff_required` | `PATCH /repos/{o}/{r}` [S10] | yes | yes (fields readable live on `<private-repo>`) |
| Actions enabled, `allowed_actions`, `sha_pinning_required` | `PUT .../actions/permissions` [S3] | yes | yes (readable live) |
| Default `GITHUB_TOKEN` permissions, PR approval by Actions | `PUT .../actions/permissions/workflow` [S3] | yes | yes (readable live) |
| Actions access level for shared components | `PUT .../actions/permissions/access` [S3] | not applicable | yes (readable live) |
| Dependabot alerts and security updates | `PUT .../vulnerability-alerts`, `PUT .../automated-security-fixes` | yes | readable live; plan gate not found in docs |
| Secret scanning, push protection | `PATCH` `security_and_analysis` [S10] | yes (enabled live on `loonvault`) | no: needs Secret Protection [S11] |
| Rulesets, branch protection | `POST .../rulesets`, `PUT .../branches/{b}/protection` | yes (`loonvault` has a ruleset, live) | no: 403 "Upgrade to GitHub Pro" (verified live) |
| Code scanning default setup | `PATCH .../code-scanning/default-setup` | yes (readable live) | no: 403 (verified live) |

- The same script can write files (Contents API or a clone and push) and open a PR. So one command can cover files and settings for both Bootstrap and Retrofit.
- Drift detection: the same script in a read-only "check" mode compares live state to the Baseline. A central scheduled run needs a fine-grained PAT or a GitHub App, because `GITHUB_TOKEN` is limited to its own repo. [S12] GitHub disables a schedule in a public repo after 60 days without activity. [S13]
- Cost: the script is code to own and test. No third-party dependency.

### 5. File-sync tools

| Tool | Status (verified live via GitHub API, 2026-10-21) | Notes |
| --- | --- | --- |
| `BetaHuhn/repo-file-sync-action` | Not archived. Last commit and release v1.21.1 on 2024-05-05. 30 open issues and PRs. | Most used (367 stars). Opens a PR per target repo on push to the source. Groups, Nunjucks templates, `deleteOrphaned` for directories. Needs a `repo`-scope PAT or a GitHub App token. [S14] |
| `Redocly/repo-file-sync-action` | Fork. Last commit 2026-10-07. No releases. | Active fork of the above; small user base (49 stars). |
| `adrianjost/files-sync-action` | Last commit 2026-10-19. Release v2.1.1 on 2026-08-26. | Small user base (28 stars). |

- File sync copies files only. It does not apply repo settings.
- Drift detection happens only when the source changes: the next sync opens a PR that reverts local edits.
- Per-repo overrides: per-repo file lists and template variables. A repo that edits a synced file loses the edit on the next sync.

### 6. Settings-as-code tools (reference)

- **Terraform `integrations/github` provider** (release v6.13.0 on 2026-07-08, verified live). Supports a user account as `owner`. [S15] It has resources for repo settings, rulesets, Actions access level, Dependabot security updates, and files (`github_repository_file`). `terraform plan` shows drift for files and settings. It needs state storage and a token. It hits the same plan gates as the REST API.
- **`repository-settings/app`** (Probot "Settings" app, active). Applies `.github/settings.yml` when it reaches the default branch. Caveat from its README: anyone with push access can gain admin rights through the file. [S16]
- **OpenSSF Allstar** (release v4.6, 2026-08-31). It checks policies and opens issues. The hosted app is retired, so you must self-host it. It is designed around organizations and a `.allstar` org repo. [S17]
- **`github/safe-settings`** (now `github-community-projects/safe-settings`, release 3.0.0). It is designed for organizations (an admin repo in the org).

## Dependabot and `uses:` refs to a private repo

- Dependabot updates actions and reusable workflows referenced as `owner/repo/...@ref` in `.github/workflows`. It ignores local refs (`./...`). [S18][S19]
- It updates SHA and tag refs, and the version comment on the same line. A SHA with no tag moves to the latest commit, not the latest release. [S18] So the source repo needs semver tags or releases for clean updates.
- `cooldown` with `default-days` works for `github-actions`; the semver-specific days do not. [S20] `loonvault` already uses `cooldown: default-days: 7` (verified live).
- "Dependabot supports both public and private repositories for GitHub Actions." [S18]
- **Open point (not verified):** the docs do not say whether Dependabot in one private repo can read a private action or workflow in another private repo of the same **personal** account. The documented grant ("Grant Dependabot access to private repositories") is for organization owners. [S21] The documented fallback is a `registries` entry of `type: git` with a token stored as a Dependabot secret. [S22] A public source removes this open point.
- Alternative bumper: one update in `github-security` can bump all callers only if a sync or Bootstrap re-run rewrites the caller refs. Otherwise each repo gets its own Dependabot PR.

## Comparison

Legend: [Sn] = source below. "live" = verified live on 2026-10-21 with read-only API calls.

| Mechanism | Access from private repos on Free | Version pinning and updates | Per-repo overrides and Modules | One-command apply to a new repo | Applies repo settings | Drift detection |
| --- | --- | --- | --- | --- | --- | --- |
| Reusable workflow, private source | Yes, after `access_level: user`; private callers only, so 7 public repos excluded [S1][S3][S4]; no plan gate (live) | `@sha` or tag [S6]; Dependabot updates it [S18][S19]; cross-repo private access for Dependabot not documented for users [S21] | Typed inputs, one caller job per Module [S6]; no extra steps inside a called job | No: needs a stub file per repo | No | Logic is central; only the stub ref ages; needs an audit job [S12] |
| Reusable workflow, public source | Yes, all 16 repos [S4] | Same as above, no Dependabot access gap [S18] | Same as above | No: needs a stub file per repo | No | Same as above |
| Composite action | Same rules as reusable workflows [S1][S4] | `@sha` or tag [S18] | Inputs; caller owns the job and adds steps [S7]; no direct secrets [S7] | No: each repo owns its workflows | No | Shared steps central; workflow files drift per repo |
| Template repo | Yes for the owner [S10] | None: one copy at creation [S8] | Edit after creation | Yes: `POST .../generate` [S10] | No: docs list files and branches only [S8][S9] | None: no link to the template [S8] |
| Bootstrap script (`gh` API) | Yes (runs as the owner) | Script pins versions in the files it writes; re-run to update | Script flags or a per-repo config file | Yes | Yes, within plan gates: private repos lack rulesets, branch protection, secret scanning, code scanning (live) [S10][S11] | Yes: a check mode; central schedule needs a PAT or App [S12][S13] |
| File-sync action | Yes with a PAT or App token [S14] | Push to source opens PRs in targets [S14]; tool itself unmaintained since 2024-05 (live) | Per-repo file lists and templates [S14]; local edits get reverted | No: add the repo to `sync.yml`, then sync | No [S14] | Only on the next sync, as a PR [S14] |
| Terraform provider (reference) | Yes, user `owner` [S15] | Pinned in config; `apply` updates | Variables per repo | Yes: add a resource, `apply` | Yes, same plan gates as REST [S15] (live for gates) | Yes: `terraform plan` |

## Paid option (reference only)

GitHub Pro adds protected branches, code owners, and required reviewers in private repos, and 3,000 Actions minutes. [S23] The live 403 message names Pro as the unlock for rulesets and branch protection on private repos (live). Secret scanning and push protection on private repos need GitHub Secret Protection. [S11]

## Combinations seen in the facts

The mechanisms are not exclusive. Facts that shape a combination:

- Only an API caller (Bootstrap script or Terraform) applies settings. Files alone never do.
- A reusable workflow or composite action keeps logic in one place, but each repo still needs a stub file.
- A private source excludes the 7 public repos and leaves a Dependabot access gap. A public source has neither problem but exposes the Baseline content.
- Hand copies already drift (finding 6). Any option that keeps copies needs a drift check.

## Sources

- [S1] Managing GitHub Actions settings for a repository, "Allowing access to components in a private repository": https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
- [S2] Changelog 2022-12-14, "Sharing actions and reusable workflows from private repositories is now GA": https://github.blog/changelog/2022-12-14-github-actions-sharing-actions-and-reusable-workflows-from-private-repositories-is-now-ga
- [S3] REST API, GitHub Actions permissions: https://docs.github.com/en/rest/actions/permissions
- [S4] Reusing workflow configurations (reference): https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations
- [S5] GitHub Actions billing: https://docs.github.com/en/billing/concepts/product-billing/github-actions
- [S6] Reuse workflows (how-to): https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
- [S7] Reusing workflow configurations (concepts): https://docs.github.com/en/actions/concepts/workflows-and-actions/reusing-workflow-configurations
- [S8] Creating a repository from a template: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template
- [S9] Creating a template repository: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository
- [S10] REST API, repositories (generate from template, update a repository): https://docs.github.com/en/rest/repos/repos
- [S11] About push protection: https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection
- [S12] GITHUB_TOKEN: https://docs.github.com/en/actions/concepts/security/github_token
- [S13] Disabling and enabling a workflow: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows
- [S14] BetaHuhn/repo-file-sync-action README: https://github.com/BetaHuhn/repo-file-sync-action
- [S15] Terraform GitHub provider docs: https://github.com/integrations/terraform-provider-github/blob/main/docs/index.md and https://github.com/integrations/terraform-provider-github/blob/main/docs/resources/actions_repository_access_level.md
- [S16] repository-settings/app README: https://github.com/repository-settings/app
- [S17] OpenSSF Allstar README: https://github.com/ossf/allstar
- [S18] Dependabot supported ecosystems and repositories, GitHub Actions section: https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories
- [S19] Changelog 2023-03-13, "Dependabot updates support reusable workflows for GitHub Actions": https://github.blog/changelog/2023-03-13-dependabot-updates-support-reusable-workflows-for-github-actions/
- [S20] Dependabot options reference (`cooldown`, `directories`): https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference
- [S21] Troubleshooting Dependabot errors (private dependencies): https://docs.github.com/en/code-security/dependabot/troubleshooting-dependabot/troubleshooting-dependabot-errors
- [S22] Configuring access to private registries for Dependabot (`type: git`): https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot
- [S23] GitHub's plans: https://docs.github.com/en/get-started/learning-about-github/githubs-plans

## Not verified

- Whether Dependabot in a private repo can read a private action or workflow in another private repo of the same personal account. The docs cover organizations only.
- Whether `secrets: inherit` works between repos of a personal account. The docs name organizations and enterprises only.
- What a template copies beyond files and branches. The docs are silent; a live test needs a new repo.
- The plan gate for Dependabot alerts and security updates on private repos. The endpoints are readable live; the docs did not state a gate.
- The `PUT` side of the Actions access level. Only `GET` was run, because this ticket changes no settings.
