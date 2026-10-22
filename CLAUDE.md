## Agent skills

### Issue tracker

GitHub Issues in `arnoldcastro5000/github-security`, through the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`. Triage rules (wayfinder issues are never triaged): `docs/agents/triage.md`.

### Domain docs

Single-context: one root `GLOSSARY.md` and `docs/adr/`. See `docs/agents/domain.md`.

### Wayfinder

The map is issue #1. Its Notes section holds the standing notes for every session; read it before choosing a ticket.

### Implement

Test suite, conventions, git (merge locally, never on GitHub), and release rules. See `docs/agents/implement.md`.

### Diagnosing bugs

Feedback loops, host limits, and known tool quirks. See `docs/agents/diagnosing-bugs.md`.

### Storage

Durable facts go in this repo (`docs/agents/`, `docs/adr/`) or in issues, never in Claude memory: Claude Code serves several projects on this host.
