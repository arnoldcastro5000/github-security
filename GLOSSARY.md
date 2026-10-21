# GitHub Security

Security controls for the GitHub repos owned by arnoldcastro5000, and the way new and existing repos get them.

## Language

**Baseline**:
The set of security controls that every in-scope repo gets: CI checks, repo settings, and local guardrails.
_Avoid_: CI security, template, standard

**Module**:
An opt-in set of checks for one stack (for example Terraform, Python, Node, or containers) that a repo gets when it contains that stack.
_Avoid_: plugin, add-on, profile

**Bootstrap**:
The one-command step that applies the Baseline to a repo.
_Avoid_: setup, install, onboarding

**Retrofit**:
Applying the Baseline to a repo that already exists.
_Avoid_: migration, backport

**In-scope repo**:
A non-fork repo owned by arnoldcastro5000, public or private.
_Avoid_: my repos, all repos

**Caller file**:
The one workflow file in an in-scope repo that calls the Baseline and its Modules by a pinned release.
_Avoid_: stub, wrapper, security workflow

**Rule pack**:
An opt-in set of extra secret-scanning rules that a repo adds to the Baseline defaults.
_Avoid_: ruleset, plugin, custom rules
