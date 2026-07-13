# Agent Factory

A portable, project-agnostic **feature-delivery factory** for Claude Code: a
resumable `/feature` orchestrator drives a team of specialist subagents —
product-owner → ux-designer → tech-lead → senior-dev → code-reviewer ∥
qa-lead → qa-runner — from a one-line request to a **merged** pull request,
pausing at configurable human gates.

Agents carry **role + process only**. Every project-specific rule comes from
the target project's own standards doc (usually `CLAUDE.md`) and one config
file, read at runtime — so the same factory installs into any repo that has
git, a PR flow, a standards doc, and runnable checks.

## What's in this repo

```
agents/                 # 7 generic role agents → installs to .claude/agents/
  product-owner.md        # scope (lane rec, ROADMAP split, duplicate check), intake, spec
  ux-designer.md          # HTML mockup + design spec (Full lane; may use a design Skill)
  tech-lead.md            # implementation plan + standards digest; re-plans on PLAN_ISSUE
  senior-dev.md           # the ONLY code writer; isolated worktree; opens the PR
  code-reviewer.md        # generic reviewer; all rules from the project's standards
  qa-lead.md              # written UAT plan (runs in parallel with review)
  qa-runner.md            # live browser execution via Playwright MCP (sonnet)
commands/               # → installs to .claude/commands/
  feature.md              # the orchestrator (resumable state machine)
  factory-init.md         # per-project bootstrap + validation; re-run = config sync
factory/                # → installs to .claude/factory/
  protocol.md             # the generic contract (phases, gates, loops, returns)
  config.template.md      # per-project template → becomes config.md via /factory-init
  conventions.md          # commit format + PR template — single source of truth
  scripts/context-usage.mjs # measures real context % for context checkpoints
skills/                 # → installs to .claude/skills/
  commit/                 # standardized Conventional Commits for manual work
  create-pr/              # standardized PR descriptions for manual work
  factory-docs/           # generate/audit a project's CLAUDE.md & docs for the factory
docs/
  how-it-works.md         # architecture & concepts (roles, phases, gates, loops, cost)
  user-guide.md           # day-to-day usage, gate playbook, troubleshooting
install.ps1 / install.sh  # copy the above into a target repo
VERSION                   # factory release → installs to .claude/factory/VERSION
EXPORT.md                 # distribution & update guide (copy-based now, plugin later)
```

## Install into a project

```bash
git clone --depth 1 https://github.com/jranukss/agent-factory
```

```powershell
# Windows
.\install.ps1 -Target "C:\path\to\your\project"
```
```bash
# macOS / Linux
./install.sh /path/to/your/project
```

Then, **in the target project**: reload the Claude Code session (agents
register at session start) → run `/factory-init` (generates and validates
`.claude/factory/config.md`) → run `/feature <request>`.

## The pipeline

```
SCOPING ─g1─► INTAKE ─g2─► SPEC ─g3─► DESIGN ─g4─► PLANNING ─g5─► IMPLEMENTING
                                     (Full only)                      │
                                                       PLAN_ISSUE ◄───┤
        ┌──────────────────────────────────────────────────────────────┘
        ▼
REVIEWING (code-review ∥ QA-plan) ⇄ FIXING ─► QA_RUNNING ⇄ FIXING
        ─► READY_TO_MERGE ─g6─► MERGED ─► post-merge pass
           (cost log)            (cleanup · learning proposal g7 · ROADMAP next phase)
```

- **Lanes:** Full (everything) · Lite (skips design) · Hotfix (task → plan →
  implement → review → merge). The product-owner recommends; you decide.
- **Gates** are configurable per lane (`ask` / `auto` / `folded`) in
  `config.md` — minimum interaction defaults: Full ≈ 4 questions per ticket,
  Lite ≈ 2, Hotfix ≈ 1, plus merge. The plan gate is always `ask`.
- **All state is on disk** (`docs/tickets/{id}/` + `STATUS.md`), so any run is
  resumable with a bare `/feature` — even after a session reload.
- **All loops are bounded** (3 iterations → escalate): intake, revisions,
  review fix loop (delta re-reviews), QA fix loop (failed scenarios only),
  re-plan.
- **Context checkpoints:** at heavy steps (implementation done, each fix-loop
  iteration, ready-to-merge) the orchestrator measures **real** context usage
  via `factory/scripts/context-usage.mjs` and, past the configured threshold,
  offers a lossless stop-and-resume in a fresh session.
- **Cost tracking:** the orchestrator logs per-ticket token/cost estimates
  into `STATUS.md` via [ccusage](https://ccusage.com). For per-agent
  dashboards, enable Claude Code's
  [OpenTelemetry export](https://code.claude.com/docs/en/monitoring-usage)
  with `OTEL_LOG_TOOL_DETAILS=1` (otherwise custom agent names are redacted).
- **Standardized git output:** `factory/conventions.md` defines one commit
  format (Conventional Commits) and one PR template for everything — the
  senior-dev agent reads it directly; the `commit` / `create-pr` skills apply
  the same file to manual work, so history is uniform whoever authored it.

**Documentation:** [docs/how-it-works.md](docs/how-it-works.md) (architecture
& concepts) · [docs/user-guide.md](docs/user-guide.md) (daily usage &
troubleshooting) · [EXPORT.md](EXPORT.md) (distribution & updates).

## Requirements in the target project

git + a GitHub remote with `gh` authenticated · a standards doc (`CLAUDE.md`;
run `/init` first if you have none) · runnable typecheck/lint/test/build
commands · (for live QA) the Playwright MCP server configured in Claude Code
and documented test accounts.

## Design principles

1. **Files are the only handoff** — subagents are isolated and pure; the
   orchestrator owns everything interactive.
2. **The factory never contradicts the project** — agents carry zero project
   rule content; the reviewer reads the standards doc in full every run.
3. **Human control where it's cheap, autonomy where it's safe** — gates
   protect requirements and hard-to-reverse decisions; everything reversible
   is decided by agents and recorded in the artifacts.
4. **Ceremony scales with risk** — lanes + gate policy, not one-size-fits-all.
