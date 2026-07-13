# Changelog

## v2.1.0 — 2026-07-12

- **`/factory-init` sync mode**: re-running it on a project with an existing
  `config.md` now *reconciles* instead of only reporting — section-by-section
  diff against the current template (add/skip per missing section; existing
  sections never modified; project-custom sections never deleted), then a
  `factory version:` stamp records the sync. Config updates after a factory
  upgrade no longer need hand-porting.
- **Design-skill reconciliation** in sync mode: verifies the configured skill
  name against the session's *registered* skills (plugin installs may be
  namespaced), offers the `## Design skill` section when a design skill is
  present but unconfigured, and when one is missing points at the skill's own
  install source — the factory never bundles or copies third-party skills
  (e.g. impeccable installs via `npx impeccable install` or its plugin
  marketplace).
- **Version tracking**: new `VERSION` file at the repo root; installers copy
  it to `.claude/factory/VERSION` (port note: pre-2.1.0 installs lack it
  until the installer is re-run). Config template gains the
  `factory version:` stamp line.
- Docs: user-guide §10 rewritten around sync mode + new §11 "Adding a design
  skill"; EXPORT.md update-flow and release-hygiene notes updated.

## v2.0.2 — 2026-07-12

- **Context checkpoints** (new protocol §10; Cost tracking renumbered to
  §11): at heavy points — senior-dev completes IMPLEMENTING, each review/QA
  fix-loop iteration, entering READY_TO_MERGE — the orchestrator measures
  **real** context usage via the new `factory/scripts/context-usage.mjs`
  (reads the session transcript's last usage block) and, at ≥ the configured
  threshold, offers "continue vs stop for a fresh window". A stop finalizes
  STATUS.md and resumes losslessly with a bare `/feature`. Script failure
  falls back to estimation — measurement never blocks the pipeline.
- **Config section added** (port to existing config.md files): `## Context
  checkpoint` with `threshold: 60` (percent; `off` disables).
- Installers copy `factory/scripts/` → `.claude/factory/scripts/`;
  `/factory-init` verifies the script; `/feature` `allowed-tools` gains
  `Bash(node *)`.

## v2.0.1 — 2026-07-12

Consistency fixes from a self-review (no behavior redesign):

- **Agents can now actually write their artifacts**: added `Write, Edit` to
  the tool lists of `product-owner`, `tech-lead`, `code-reviewer`, `qa-lead`,
  and `qa-runner` — the protocol's purity rule and each agent's own procedure
  require them to write ticket files, but their frontmatter only allowed
  read-only tools. Each agent's rules now state the Write/Edit tools are for
  ticket artifacts only (senior-dev remains the only application-code writer).
- **`install.sh` hardening**: the `[ -f config.md ] && echo …` one-liner
  became an explicit `if` — behavior was correct today (bash's `set -e`
  exempts failed `&&` lists mid-script), but the pattern silently yields a
  nonzero exit if it ever becomes the script's last command.
- **`04-review.md` authorship clarified**: the code-reviewer writes (and in
  delta mode overwrites) `04-review.md` itself; `feature.md` and the agent's
  output-format section now say so explicitly.
- **`/feature` can fire push notifications**: added `PushNotification` to
  `feature.md`'s `allowed-tools` (the config template offers it as a gate
  notification mechanism).
- **Mockup Artifact URL is now persisted**: the orchestrator appends the
  published Artifact URL to `02-design.md` and logs it in `STATUS.md`
  (protocol §2 always claimed the URL lived there; nothing wrote it).
- **`qa-runner` tool list cleaned**: removed nonexistent Playwright MCP tools
  (`browser_drop`, singular `browser_network_request`).

## v2.0.0 — 2026-07-12

Initial v2 release. Everything from the CountIt v1 factory plus the
improvements from the 2026-07-12 review (`countit/docs/factory-review.md`):

- **Genericized code-reviewer** — zero hardcoded rule content (v1 had rules
  that drifted against CLAUDE.md); adds plan-scope enforcement and delta
  re-review mode for fix loops.
- **QA split shipped**: `qa-lead` (opus, written UAT plan, runs in parallel
  with review; includes design-conformance scenarios) + `qa-runner` (sonnet,
  live Playwright execution, failed-scenarios-only re-run mode).
- **Full lifecycle**: merge-check + post-merge pass (worktree/branch cleanup,
  learning-capture gate, ROADMAP next-phase continuation); terminal phases
  `MERGED`/`CLOSED` with fixed resume semantics (`READY_TO_MERGE` resumable).
- **Hotfix lane** and a per-lane **gate policy table** (`ask`/`auto`/`folded`)
  for minimum-but-not-zero interaction; optional gate notifications.
- **All loops bounded at 3** (intake, revisions, fix, QA-fix, re-plan) with
  escalation; malformed-return fallback; AskUserQuestion chunking.
- **senior-dev hardening**: idempotent worktree reuse on resume, sync with
  default branch before PR and on fix-loop pushes, `build` added to the
  verification contract, fix-loop policy aligned with protocol §6 (fix
  everything unless agreed-skip).
- **product-owner**: duplicate-work (already-implemented) check in the scope
  pass; moved to sonnet.
- **Cost tracking**: per-ticket `## Cost` entries in STATUS.md via ccusage.
- **`/factory-init`**: config generation from template with detection, plus
  prerequisite/registration validation.
- **Concurrency policy**: tickets sequential by default; second ticket may
  run only through PLANNING.
- Install scripts (`install.ps1`/`install.sh`) and `EXPORT.md` distribution
  plan.
- **Standardized git output**: `factory/conventions.md` (Conventional
  Commits + a single PR-description template) read directly by senior-dev,
  plus `commit` and `create-pr` skills that apply the same file to manual
  work.
- **`factory-docs` skill**: generates or audits a project's standards doc
  (CLAUDE.md) and supporting docs (tickets README, QA test-accounts) into
  the section structure the factory's role-map consumes.
- **Documentation**: `docs/how-it-works.md` (architecture & concepts) and
  `docs/user-guide.md` (daily usage, gate playbook, troubleshooting).
- Installers now copy `skills/` → `.claude/skills/`; `/factory-init`
  validates conventions.md and the three skills.
