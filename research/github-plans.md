# GitHub plans: security controls for public and private repos

Research for issue #2. Checked on 2026-10-21.

## Question

For each control, what does GitHub Free give a personal public repo and a personal private repo? What do GitHub Pro and a free organization add? What is the best paid option to close the private-repo gap, and what does it cost? The map is free-only, so the paid option is for reference only.

## Answer

- A public repo on GitHub Free gets every control in the list. All of these controls are verified live on `arnoldcastro5000/loonvault`.
- A private repo on GitHub Free loses two groups of controls.
  - **Group A (branch rules)**: rulesets, classic branch protection, and required status checks. GitHub Pro adds this group to user-owned private repos.
  - **Group B (Advanced Security)**: secret scanning, push protection, code scanning (SARIF upload and CodeQL default setup), and dependency review. No personal plan adds this group. A user-owned repo on github.com cannot get Group B, except on Enterprise Managed Users. An org-owned repo gets Group B only on GitHub Team or Enterprise, with a paid add-on.
- A free organization adds nothing for private repos in Group A or Group B.
- Private vulnerability reporting is for public repos only, on every plan.
- Dependabot alerts, Dependabot security updates, and all Actions settings in the list work on private repos on GitHub Free.

## Table

Legend: **Yes** means available. **No** means not available. "live" means verified with a read-only `gh api` call on this account on 2026-10-21 (see [Live checks](#live-checks)). A bracketed link is the primary source.

| Control | Free, public | Free, private | Pro, private | Free org, private | Best paid option for private |
| --- | --- | --- | --- | --- | --- |
| Rulesets (branch and tag) | Yes, live (L1) | No, live (L2) | Yes [rulesets] | No [rulesets] | Pro, about $4/month [faq]; or Team, $4/user/month [pricing] |
| Push rulesets | No [rulesets] | No [rulesets] | No [rulesets] | No [rulesets] | Team, private repos only [rulesets] |
| Classic branch protection | Yes, live (L3) | No, live (L4) | Yes [protected], [plans] | No [protected] | Pro or Team, same prices as rulesets |
| Required status checks | Yes, live (L1) | No, live (L2, L4) | Yes [rulesets], [protected] | No [rulesets] | Pro or Team. The check is a rule inside a ruleset or a branch protection rule. |
| Secret scanning | Yes, live (L5) | No, live (L6) | No [secret] | No [secret], [ghas] | Org on Team plus Secret Protection, $19/active committer/month [secplans], [ghas] |
| Push protection (repo setting) | Yes, live (L5) | No [ghas], [push] | No [secret], [push] | No [ghas] | Org on Team plus Secret Protection, $19/active committer/month [secplans] |
| Code scanning (SARIF upload) | Yes, live (L7) | No, live (L8) | No [sarif] | No [sarif], [ghas] | Org on Team plus Code Security, $30/active committer/month [secplans], [cs] |
| CodeQL default setup | Yes, live (L9) | No, live (L8) | No [default] | No [default], [ghas] | Org on Team plus Code Security, $30/active committer/month [secplans] |
| Dependabot alerts | Yes, live (L10) | Yes [dbalerts], [plans]; live: off, not plan-gated (L11) | Yes [dbalerts] | Yes [dbalerts] | Not needed |
| Dependabot security updates | Yes, live (L5) | Yes [dbupdates]; live: setting readable (L11) | Yes [dbupdates] | Yes [dbupdates] | Not needed |
| Dependency review | Yes, live (L12), [depreview] | No, live (L13) | No [depreview] | No [depreview], [ghas] | Org on Team plus Code Security, $30/active committer/month [depreview], [secplans] |
| Private vulnerability reporting | Yes, live (L14) | No, live (L15), [pvr] | No [pvr] | No [pvr] | None. Public repos only on every plan [pvr]. |
| Actions allowed-actions policy | Yes, live (L16), [actions] | Yes, live (L16), [actions] | Yes [actions] | Yes, also at org level [actions] | Not needed |
| Actions SHA-pinning policy | Yes, live (L16), [actions] | Yes, live (L16), [actions] | Yes [actions] | Yes, also at org level [actions] | Not needed |
| Default `GITHUB_TOKEN` permissions | Yes, live (L17), [actions] | Yes, live (L17), [actions] | Yes [actions] | Yes, the org default is inherited [actions] | Not needed |
| Reusable-workflow access from private repos | Not applicable. Any repo can call a public workflow [reuse]. | Yes, live (L18), [share] | Yes [share] | Yes, at org scope [actions] | Not needed |

## Notes on the table

1. **Rulesets and branch protection.** The docs say: "Rulesets are available in public repositories with GitHub Free and GitHub Free for organizations, and in public and private repositories with GitHub Pro, GitHub Team, and GitHub Enterprise Cloud." [rulesets]. The text for protected branches is the same [protected]. On this account, the API for a private repo returns HTTP 403 "Upgrade to GitHub Pro or make this repository public to enable this feature." (L2, L4).
2. **Push rulesets.** The docs say: "Push rulesets are available for the GitHub Team plan in internal and private repositories" [rulesets]. They are not on Free, Pro, or a free org.
3. **Group B on user-owned repos.** For user-owned repos, the secret scanning docs name only Enterprise Cloud with Enterprise Managed Users and Enterprise Server [secret]. The GHAS docs say: "You must be on a GitHub Team or GitHub Enterprise plan in order to purchase GitHub Code Security or GitHub Secret Protection." [ghas]. Thus GitHub Pro does not add Group B.
4. **Push protection for users.** This is a separate account-level control. It is on by default for every account. It "stops you from pushing secrets to public repositories on GitHub" [push]. It does not protect pushes to private repos.
5. **Dependency review conflict in the docs.** The dependency review page says the feature is available for "Public repositories on GitHub.com" [depreview]. The GHAS comparison table marks dependency review as "No" for a public repo without Code Security [ghas]. The live API agrees with the dependency review page: the compare endpoint returns 200 on the public repo and 403 on the private repo (L12, L13).
6. **Dependabot on the private test repo.** On `<private-repo>`, Dependabot alerts are off. The API says "Dependabot alerts are disabled for this repository." (HTTP 403). This message names a setting, not a plan. The "upgrade" message from rulesets does not appear. The docs say Dependabot alerts "are available for organization-owned and user-owned repositories" [dbalerts]. The docs say Dependabot security updates are available for "All repositories on GitHub" [dbupdates].
7. **Actions settings.** The repo-level Actions settings page shows no plan limit for the allowed-actions policy, the "Require actions to be pinned to a full-length commit SHA" option, or the default `GITHUB_TOKEN` permissions [actions]. The API returns these settings on the private repo with no plan error (L16, L17). The SHA-pinning option applies to actions. The docs say: "Reusable workflows can still be referenced by tag." [actions].
8. **Reusable workflows from a private repo.** A private repo can share its actions and reusable workflows with other private repos of the same owner. The setting is "Accessible from repositories owned by 'USER NAME' user" [actions], [share]. The docs say: "Access is allowed only from private repositories." [actions]. A public caller can use only public workflows [reuse].

## Best paid option (reference only)

There are two gaps. The paid options are different for each gap.

| Gap | Cheapest paid option | Price | Source |
| --- | --- | --- | --- |
| Group A on user-owned private repos | GitHub Pro | $4/month (2020 docs FAQ; the current pricing page does not show Pro) | [faq], [pricing] |
| Group A on org-owned private repos | GitHub Team | $4/user/month | [pricing] |
| Group B (secret scanning, push protection) | Org on GitHub Team plus GitHub Secret Protection | $19/active committer/month, plus Team | [secplans], [ghas] |
| Group B (code scanning, CodeQL, dependency review) | Org on GitHub Team plus GitHub Code Security | $30/active committer/month, plus Team | [secplans], [ghas] |

- To close both gaps for one committer, the total is $4 (Team) + $19 + $30 = **$53/month**. This option requires a transfer of the private repos from the user account to an organization.
- GitHub Enterprise starts at $21/user/month [pricing]. It also closes both gaps with the same add-ons, but it costs more than Team.
- GHAS billing counts each unique active committer once. A committer is "active" if one of their commits was pushed in the last 90 days. GitHub App bots are not counted [billing].

## Live checks

All calls are read-only. No repo setting changed. Public repo: `arnoldcastro5000/loonvault`. Private repo: `arnoldcastro5000/<private-repo>`. Both repos use `main` as the default branch.

| ID | Call | Result |
| --- | --- | --- |
| L1 | `gh api repos/arnoldcastro5000/loonvault/rulesets/17643421` | 200. Ruleset `protect-main` is active. Rule types: `deletion`, `non_fast_forward`, `pull_request`, `required_status_checks`. |
| L2 | `gh api repos/arnoldcastro5000/<private-repo>/rulesets` | 403 "Upgrade to GitHub Pro or make this repository public to enable this feature." |
| L3 | `gh api repos/arnoldcastro5000/loonvault/branches/main/protection` | 404 "Branch not protected". The feature is available but not in use. |
| L4 | `gh api repos/arnoldcastro5000/<private-repo>/branches/main/protection` | 403 "Upgrade to GitHub Pro or make this repository public to enable this feature." |
| L5 | `gh api repos/arnoldcastro5000/loonvault` (`security_and_analysis`) | `secret_scanning`, `secret_scanning_push_protection`, and `dependabot_security_updates` are `enabled`. |
| L6 | `gh api repos/arnoldcastro5000/<private-repo>/secret-scanning/alerts` | 404 "Secret scanning is disabled on this repository." `security_and_analysis` on the repo is `null`. |
| L7 | `gh api repos/arnoldcastro5000/loonvault/code-scanning/alerts` | 404 "no analysis found". The feature is available but has no upload. |
| L8 | `gh api repos/arnoldcastro5000/<private-repo>/code-scanning/alerts` and `.../code-scanning/default-setup` | 403 "Code scanning is not enabled for this repository." |
| L9 | `gh api repos/arnoldcastro5000/loonvault/code-scanning/default-setup` | 200. `state: not-configured`. Languages detected. |
| L10 | `gh api repos/arnoldcastro5000/loonvault/dependabot/alerts` | 200. The list contains alerts. |
| L11 | `gh api repos/arnoldcastro5000/<private-repo>/dependabot/alerts` and `.../automated-security-fixes` | 403 "Dependabot alerts are disabled for this repository." Security updates: `{"enabled":false,"paused":false}`. |
| L12 | `gh api repos/arnoldcastro5000/loonvault/dependency-graph/compare/HEAD~1...HEAD` | 200 (`[]`). |
| L13 | `gh api repos/arnoldcastro5000/<private-repo>/dependency-graph/compare/HEAD~1...HEAD` | 403 "Forbidden". |
| L14 | `gh api repos/arnoldcastro5000/loonvault/private-vulnerability-reporting` | 200 `{"enabled":true}`. |
| L15 | `gh api repos/arnoldcastro5000/<private-repo>/private-vulnerability-reporting` | 404 "Not Found". |
| L16 | `gh api repos/arnoldcastro5000/{loonvault,<private-repo>}/actions/permissions` | 200 on both: `{"enabled":true,"allowed_actions":"all","sha_pinning_required":false}`. |
| L17 | `gh api repos/arnoldcastro5000/{loonvault,<private-repo>}/actions/permissions/workflow` | 200 on both: `default_workflow_permissions: read`, `can_approve_pull_request_reviews: false`. |
| L18 | `gh api repos/arnoldcastro5000/<private-repo>/actions/permissions/access` | 200 `{"access_level":"none"}`. On `loonvault`: 422 "Access policy only applies to internal and private repositories." |

## Not verified

- **Pro and free-org cells.** The account is on GitHub Free and owns no organization. These cells come from the docs only.
- **Write access on Free private repos.** The live checks only read the settings. They do not prove that a write succeeds on a Free private repo (for example, `sha_pinning_required: true` or `access_level: user`). The docs show no plan limit for these writes.
- **Current GitHub Pro price.** The current pricing page and the pricing calculator do not show a static Pro price. The $4/month figure comes from a 2020 docs FAQ [faq].

## Sources

- `plans`: <https://docs.github.com/en/get-started/learning-about-github/githubs-plans>
- `rulesets`: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets>
- `protected`: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches>
- `secret`: <https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning>
- `push`: <https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection>
- `ghas`: <https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security>
- `cs`: <https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning>
- `sarif`: <https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github>
- `default`: <https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning>
- `dbalerts`: <https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts>
- `dbupdates`: <https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/about-dependabot-security-updates>
- `depreview`: <https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review>
- `pvr`: <https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability>
- `actions`: <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository>
- `reuse`: <https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations>
- `share`: <https://docs.github.com/en/actions/how-tos/reuse-automations/share-across-private-repositories>
- `billing`: <https://docs.github.com/en/billing/concepts/product-billing/github-advanced-security>
- `pricing`: <https://github.com/pricing>
- `secplans`: <https://github.com/security/plans>
- `faq`: <https://docs.github.com/en/get-started/learning-about-github/faq-about-changes-to-githubs-plans>

[plans]: https://docs.github.com/en/get-started/learning-about-github/githubs-plans
[rulesets]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
[protected]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
[secret]: https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning
[push]: https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection
[ghas]: https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security
[cs]: https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning
[sarif]: https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github
[default]: https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning
[dbalerts]: https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts
[dbupdates]: https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/about-dependabot-security-updates
[depreview]: https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review
[pvr]: https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability
[actions]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
[reuse]: https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations
[share]: https://docs.github.com/en/actions/how-tos/reuse-automations/share-across-private-repositories
[billing]: https://docs.github.com/en/billing/concepts/product-billing/github-advanced-security
[pricing]: https://github.com/pricing
[secplans]: https://github.com/security/plans
[faq]: https://docs.github.com/en/get-started/learning-about-github/faq-about-changes-to-githubs-plans
